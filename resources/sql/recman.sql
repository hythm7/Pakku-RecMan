-- sub create-table-distributions( )
CREATE TABLE IF NOT EXISTS 'distributions' (

  'source'              TEXT     NOT NULL,
  'meta'                TEXT     NOT NULL,
  'identity'            TEXT     NOT NULL,
  'name'                TEXT     NOT NULL,
  'ver'                 TEXT     NOT NULL,
  'auth'                TEXT,
  'api'                 TEXT,
  'description'         TEXT,
  'source-url'          TEXT,
  'build'               TEXT,
  'builder'             TEXT,
  'author'              TEXT,
  'support-source'      TEXT,
  'support-email'       TEXT,
  'support-mailinglist' TEXT,
  'support-bugtracker'  TEXT,
  'support-irc'         TEXT,
  'support-phone'       TEXT,
  'support-license'     TEXT,
  'production'          INTEGER,
  'license'             TEXT,
  'raku'                TEXT,

  PRIMARY KEY ( identity )
)

-- sub create-table-provides( )
CREATE TABLE IF NOT EXISTS 'provides' (

  'identity' TEXT NOT NULL,
  'unit'     TEXT NOT NULL,
  'file'     TEXT NOT NULL,

  PRIMARY KEY ( identity, unit )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-deps( )
CREATE TABLE IF NOT EXISTS 'deps' (

  'identity' TEXT NOT NULL,
  'phase'    TEXT NOT NULL,
  'need'     TEXT NOT NULL,
  'use'      TEXT NOT NULL,

  PRIMARY KEY ( identity, phase, need, use )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)


-- sub create-table-resources( )
CREATE TABLE IF NOT EXISTS 'resources' (

  'identity' TEXT NOT NULL,
  'resource' TEXT NOT NULL,

  PRIMARY KEY ( identity, resource )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-emulates( )
CREATE TABLE IF NOT EXISTS 'emulates' (

  'identity' TEXT NOT NULL,
  'unit'     TEXT NOT NULL,
  'use'      TEXT NOT NULL,

  PRIMARY KEY ( identity, unit )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-supersedes( )
CREATE TABLE IF NOT EXISTS 'supersedes' (

  'identity' TEXT NOT NULL,
  'unit'     TEXT NOT NULL,
  'use'      TEXT NOT NULL,

  PRIMARY KEY ( identity, unit )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-superseded( )
CREATE TABLE IF NOT EXISTS 'superseded-by' (

  'identity' TEXT NOT NULL,
  'unit'     TEXT NOT NULL,
  'use'      TEXT NOT NULL,

  PRIMARY KEY ( identity, unit )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-excludes( )
CREATE TABLE IF NOT EXISTS 'excludes' (

  'identity' TEXT NOT NULL,
  'unit'     TEXT NOT NULL,
  'use'      TEXT NOT NULL,

  PRIMARY KEY ( identity, unit, use )

  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-authors( )
CREATE TABLE IF NOT EXISTS 'authors' (

  'identity' TEXT NOT NULL,
  'author'   TEXT NOT NULL,

  PRIMARY KEY ( identity , author )
  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub create-table-tags( )
CREATE TABLE IF NOT EXISTS 'tags' (

  'identity' TEXT NOT NULL,
  'tag'   TEXT NOT NULL,

  PRIMARY KEY ( identity , tag )
  FOREIGN KEY ( identity ) REFERENCES distributions ( identity )
)

-- sub insert-into-distributions(Str $source, Str $meta, Str $identity, Str $name, Str $ver, Str $auth, Str $api, Str $description, Str $source-url, Str $build, Str $builder, Str $author, Str $support-source, Str $support-email, Str $support-mailinglist, Str $support-bugtracker, Str $support-irc, Str $support-phone, Str $support-license, Int $production, Str $license, Str $raku --> +)
INSERT INTO 'distributions' (
  'source', 'meta', 'identity', 'name', 'ver', 'auth', 'api',
  'description', 'source-url', 'build', 'builder', 'author', 'support-source',
  'support-email', 'support-mailinglist', 'support-bugtracker',
  'support-irc', 'support-phone', 'support-license', 'production',
  'license', 'raku'
  )
  VALUES (
    $source, $meta, $identity, $name, $ver, $auth,
    $api, $description, $source-url, $build, $builder, $author,
    $support-source, $support-email, $support-mailinglist,
    $support-bugtracker, $support-irc, $support-phone,
    $support-license, $production, $license, $raku
  )
  ON CONFLICT DO NOTHING

-- sub insert-into-provides(Str $identity, Str $unit, Str $file -->+)
INSERT INTO 'provides' ('identity', 'unit', 'file' )
  VALUES ( $identity, $unit, $file )
  ON CONFLICT DO NOTHING

-- sub insert-into-deps(Str $identity, Str $phase, Str $need, Str $use -->+)
INSERT INTO 'deps' ('identity', 'phase', 'need', 'use' )
  VALUES ( $identity, $phase, $need, $use )
  ON CONFLICT DO NOTHING


-- sub insert-into-resources(Str $identity, Str $resource -->+)
INSERT INTO 'resources' ('identity', 'resource' )
  VALUES ( $identity, $resource )
  ON CONFLICT DO NOTHING

-- sub insert-into-emulates(Str $identity, Str $unit, Str $use -->+)
INSERT INTO 'emulates' ('identity', 'unit', 'use' )
  VALUES ( $identity, $unit, $use )
  ON CONFLICT DO NOTHING

-- sub insert-into-supersedes(Str $identity, Str $unit, Str $use -->+)
INSERT INTO 'supersedes' ('identity', 'unit', 'use' )
  VALUES ( $identity, $unit, $use )
  ON CONFLICT DO NOTHING

-- sub insert-into-superseded(Str $identity, Str $unit, Str $use -->+)
INSERT INTO 'superseded-by' ('identity', 'unit', 'use' )
  VALUES ( $identity, $unit, $use )
  ON CONFLICT DO NOTHING

-- sub insert-into-excludes(Str $identity, Str $unit, Str $use -->+)
INSERT INTO 'excludes' ('identity', 'unit', 'use' )
  VALUES ( $identity, $unit, $use )
  ON CONFLICT DO NOTHING

-- sub insert-into-authors(Str $identity, Str $author -->+)
INSERT INTO 'authors' ('identity', 'author' )
  VALUES ( $identity, $author )
  ON CONFLICT DO NOTHING

-- sub insert-into-tags(Str $identity, Str $tag -->+)
INSERT INTO 'tags' ('identity', 'tag' )
  VALUES ( $identity, $tag )
  ON CONFLICT DO NOTHING


-- sub select(Str $name! --> @)
SELECT distributions.identity, name, ver, auth, api
  FROM      distributions
  LEFT JOIN provides
  ON        provides.identity = distributions.identity
  WHERE     name = $name or unit = $name
  GROUP BY  distributions.identity

-- sub select-meta(Str $identity! --> $)
SELECT meta
  FROM     distributions
  WHERE    identity = $identity

-- sub everything( --> @)
SELECT meta FROM distributions

