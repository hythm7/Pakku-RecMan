#!/usr/bin/env raku 

use DB::SQLite;
use Pakku::RecMan;


multi MAIN ( 'update', Str:D :$database!, IO() :$store! ) {

  my $db = DB::SQLite.new: filename => $database;

  Pakku::RecMan.new( :$db, :$store ).update;

}

multi MAIN ( 'serve', Str:D :$database!, IO() :$store!, *%cooperate ) {

  my $db = DB::SQLite.new: filename => $database;

  my @cooperate = flat %cooperate<cooperate> if %cooperate;

  Pakku::RecMan.new( :$db, :$store, :@cooperate ).serve;

}

