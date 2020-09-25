NAME
====
`Pakku::RecMan` - Recommendation Manager for `Pakku`

SYNOPSIS
========
Parse all distributions archives in `store` directory and add them to `db`

```
recman.raku --db=recman.sqlite --store=/path/to/distributions/archives update
```

`serve` the disributions's `meta` and archives, ( also can cooperate with other `Pakku::RecMan`s )

```
PAKKU_RECMAN_HOST=localhost PAKKU_RECMAN_PORT=4242 recman.raku --db=recman.sqlite --store=/store --cooperate=recman.cpan.org --cooperate=recman.pakku.org serve;
```

INSTALLATION
===========
```
pakku add Pakku::RecMan

# or 

zef install Pakku::RecMan
```


DESCRIPTION
===========
`Pakku::RecMan` is a Recommendation Manager for `Pakku`

 * `store` is an `IO::Path` directory containing the `*.tar.gz` archives of the `distributions` you want to serve.

 * To request `meta` of a distribution:
`http://recman.pakku.org/meta?name=MyModule&ver=0.0.1`


 * Download `archive` of a distribution:
`http://recman.pakku.org/archive/distribution-path-provided-in-meta.tar.gz`
( The returned `meta` will have `recman` `source` key containing the `url` of the archive )


 * Currently `recman.pakku.org` has `meta` and `archives` for all `Raku` `distribution`'s in `p6c` and `cpan`, ( Except distributions with issues in `META` file )

 * Can request any distribution's `meta`, eg:
`http://recman.pakku.org/meta?name=Inline::Perl5&ver=0.50` 

 * When running in `cooperative` mode, `RecMan`s can cooperate together to fulfill a request

USE CASE
========
Having `MyModule1` and `MyModule2` served by local `RecMan` running in cooperative mode with other `RecMan`s. Requesting `MyModule1`'s `meta` will provide `MyModule1` from the local `RecMan` and dependencies from the cooperative `RecMan`s


CREDITS
======
* I'm using [crai](https://github.com/chloekek/crai/tree/master/crai) to mirror locally the archives of the distributions in `p6c` and `cpan`

* `db` schema is stolen from `crai` and modified to suit `Pakku`'s needs 

AUTHOR
======
Haytham Elganiny <elganiny.haytham@gmail.com>

COPYRIGHT AND LICENSE
=====================
Copyright 2020 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

