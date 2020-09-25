#!/usr/bin/env raku 

use Pakku::RecMan;


multi MAIN ( 'update', Str() :$db!, IO() :$store! ) {

  Pakku::RecMan.new( :$db, :$store ).update;
}

multi MAIN ( 'serve', Str() :$db!, IO() :$store!, *%cooperate ) {

  my @cooperate = flat %cooperate<cooperate> if %cooperate;

  Pakku::RecMan.new( :$db, :$store, :@cooperate ).serve;

}

