use JSON::Fast;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Log::File;

use Pakku::RecMan::Database;
use Pakku::RecMan::Client;
use Pakku::Spec;


unit class Pakku::RecMan;

has IO $!store;
has Pakku::RecMan::Database $!db;
has Pakku::RecMan::Client   $!recman;

has $!host = %*ENV<PAKKU_RECMAN_HOST>;
has $!port = %*ENV<PAKKU_RECMAN_PORT>;


method recommend ( Str:D :$name!, Str :$ver, Str :$auth, Str :$api ) {

  my %spec;

  %spec<name>    = $name    if defined $name;
  %spec<ver>     = $ver     if defined $ver;
  %spec<auth>    = $auth    if defined $auth;
  %spec<api>     = $api     if defined $api;

  my $spec = Pakku::Spec.new: %spec;

  my @candy = $!db.select: :$name;

  unless @candy {

    return Empty unless $!recman;

    my %meta = $!recman.recommend: :$spec;

    return to-json %meta;
  }

  @candy .= grep( -> %candy { %candy ~~ $spec } );

  return Empty unless @candy;

  my $candy = @candy.reduce( &latest );

  my $identity = $candy<identity>;

  my %meta = from-json $!db.select-meta: :$identity;

  %meta<source> = "http://$!host/archive/{%meta<source>}";

  to-json %meta;

}

method everything ( ) {

  $!db.everything.map( *.values ).flat.map( -> $json { from-json $json } )

}

method update ( ) { $!db.update }

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

submethod BUILD ( :$db, IO :$!store!, :@cooperate ) {


  $!db     = Pakku::RecMan::Database.new: :$!store, filename => $db;

  $!recman = Pakku::RecMan::Client.new:   url => @cooperate if @cooperate;

}

