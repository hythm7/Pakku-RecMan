use JSON::Fast;
use File::Find;
use Archive::Libarchive;
use Archive::Libarchive::Constants;
use DB::SQLite;
use Badger ~%?RESOURCES<sql/recman.sql>;

use Pakku::Meta;


unit class Pakku::RecMan::Database;

has IO         $.store;
has DB::SQLite $.db;

method select ( :$name! ) {

  select $!db, $name;

}

method everything ( ) {

  everything $!db;

}


method select-meta ( :$identity! ) {

  #TODO: Sort version correctly
  select-meta $!db, $identity;

}

method update ( ) {

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
}

submethod BUILD ( IO() :$!store!, :$filename! ) {

  $!db = DB::SQLite.new: :$filename;

  #TODO: set-journal-mode-wal       $!db;
  
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

}

