use JSON::Fast;
use File::Find;
use Archive::Libarchive;
use Archive::Libarchive::Constants;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Log::File;
use Badger ~%?RESOURCES<sql/recman.sql>;

use Pakku::Spec;
use Pakku::Meta;
use Pakku::RecMan::Client;



unit class Pakku::RecMan;

has IO                    $!store;
has                       $!db;
has Pakku::RecMan::Client $!recman;

has $!host = %*ENV<PAKKU_RECMAN_HOST>;
has $!port = %*ENV<PAKKU_RECMAN_PORT>;


method recommend ( Str:D :$name!, Str :$ver, Str :$auth, Str :$api ) {

  LEAVE $!db.finish;

  my %spec;

  %spec<name>    = $name    if defined $name;
  %spec<ver>     = $ver     if defined $ver;
  %spec<auth>    = $auth    if defined $auth;
  %spec<api>     = $api     if defined $api;

  my $spec = Pakku::Spec.new: %spec;

  my @candy = self.select: :$name;

  unless @candy {

    return Empty unless $!recman;

    my %meta = $!recman.recommend: :$spec;

    return to-json %meta;
  }

  @candy .= grep( -> %candy { %candy ~~ $spec } );

  return Empty unless @candy;

  my $candy = @candy.reduce( &latest );

  my $identity = $candy<identity>;

  my %meta = from-json self.select-meta: :$identity;

  %meta<source> = "http://$!host/archive/{%meta<source>}";

  to-json %meta;

}

method select ( :$name! ) {

  select $!db, $name;


}

method select-meta ( :$identity! ) {

  #TODO: Sort version correctly
  select-meta $!db, $identity;

}

method everything ( ) {

  LEAVE $!db.finish;

  everything $!db
    ==> map( *.values )
    ==> flat( )
    ==> map( -> $json { from-json $json } );

}

method update ( ) {

  LEAVE $!db.finish;

  create-table-distributions $!db;
  create-table-provides      $!db;
  create-table-deps          $!db;
  create-table-resources     $!db;
  create-table-emulates      $!db;
  create-table-supersedes    $!db;
  create-table-superseded    $!db;
  create-table-excludes      $!db;
  create-table-authors       $!db;
  create-table-tags          $!db;

  for find( dir => $!store ) -> $path {

    my $m = quietly try from-json extract-meta :$path;

    next unless $m;

    $m{ grep { not defined $m{ $_ } }, $m.keys}:delete;

    $m<source> = $path.basename.Str;

    my $meta = quietly try Pakku::Meta.new: meta => $m;

    next unless $meta;

    my $build = to-json $meta.build if $meta.build;

    say $meta.identity.Str;

    quietly insert-into-distributions(
      $!db,
      $meta.source,
      $meta.to-json,
      $meta.identity.Str,
      $meta.name,
      $meta.ver.Str,
      $meta.auth,
      $meta.api.Str,
      $meta.description,
      $meta.source-url,
      $build,
      $meta.builder,
      $meta.author,
      $meta.support<source>,
      $meta.support<email>,
      $meta.support<mailinglist>,
      $meta.support<bugtracker>,
      $meta.support<irc>,
      $meta.support<phone>,
      $meta.support<license>,
      $meta.production,
      $meta.license,
      $meta.raku-version.Str
    );

    $meta.provides.map( { insert-into-provides $!db, $meta.identity.Str, .key, .value } ) ;

    my %h = $meta.deps;
    my @deps = %h.keys Z %h{%h.keys}.map(|*.keys) Z %h{%h.keys}.map(|*.values);

    @deps.map( -> @dep {

      for flat @dep[2] -> $dep is rw {

        $dep = to-json $dep if $dep ~~ Hash;
        insert-into-deps $!db, $meta.identity.Str, @dep[0], @dep[1], $dep;

     }
    });

    $meta.resources.grep( *.defined ).map( -> $resource { insert-into-resources $!db, $meta.identity.Str, $resource } ) ;

    $meta.emulates.grep( *.defined ).map( { insert-into-emulates $!db, $meta.identity.Str, .key, .value } ) ;

    $meta.supersedes.grep( *.defined ).map( { insert-into-supersedes $!db, $meta.identity.Str, .key, .value } ) ;

    $meta.superseded-by.grep( *.defined ).map( { insert-into-superseded $!db, $meta.identity.Str, .key, .value } ) ;

    $meta.excludes.grep( *.defined ).map( { insert-into-excludes $!db, $meta.identity.Str, .key, .value } ) ;

    $meta.authors.grep( *.defined ).map( -> $author { insert-into-authors $!db, $meta.identity.Str, $author } ) ;

    $meta.tags.grep( *.defined ).map( -> $tag { insert-into-tags $!db, $meta.identity.Str, $tag } ) ;

  }

}

method serve ( ) {

  my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => $!host || die("Missing PAKKU_RECMAN_HOST in environment"),
    port => $!port || die("Missing PAKKU_RECMAN_PORT in environment"),
    application => self!routes,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
  );

  $http.start;

  say "Listening at http://$!host:$!port>";

  react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
  }
}

method !routes ( ) {

  route {
    
    get -> 'meta', Str:D :$name!, Str :$ver, Str :$auth, Str :$api {
      content 'applicationtext/json', self.recommend: :$name :$ver :$auth :$api;
    }

    get -> 'archive', $path {
      static $!store, $path
    }

    get -> 'meta', '42' {
      content 'applicationtext/json', to-json self.everything;
    }

    get -> {
      content 'text/html', "<h1> Pakku::RecMan </h1>";
    }
  }

}


sub latest ( %left, %right ) {

  %left<ver>.Version ≤ %right<ver>.Version
    ?? %right
    !! %left; 
}

sub extract-meta ( Str() :$path! ) {

	my Archive::Libarchive $a .= new: operation => LibarchiveRead, file => $path;


	my @meta = < META6.json META.json META6.info META.info >;

	my Archive::Libarchive::Entry $e .= new;

	while $a.next-header($e) {

	if $e.pathname.split( '/' ).skip ~~ any @meta {

		return $a.read-file-content($e).decode('utf-8') if $e.size > 0;

	}
		$a.data-skip;

	}

	LEAVE $a.close;

}

submethod BUILD ( :$!db, IO :$!store!, :@cooperate ) {

  $!recman = Pakku::RecMan::Client.new: url => @cooperate if @cooperate;

}

