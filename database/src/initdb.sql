-- Just initilization of the database.
CREATE DATABASE bublr;

-- connect to bublr database and not default postgres db.
\c bublr;

CREATE TABLE "users" (
	"id" SERIAL PRIMARY KEY,
	"username" VARCHAR(50) UNIQUE NOT NULL,
	"password" VARCHAR(75) UNIQUE NOT NULL,
	"firstname" VARCHAR(75), -- Optional
	"lastname" VARCHAR(75), -- Optional
	"email" VARCHAR(500) UNIQUE NOT NULL,
	"picture" VARCHAR(3000),
	"bio" VARCHAR(1000),
	"admin" BOOLEAN NOT NULL DEFAULT 'false'
);

CREATE TABLE "fountains" (
	"id" SERIAL PRIMARY KEY,
	"user_id" BIGINT REFERENCES "users",
	"latitude" DECIMAL NOT NULL,
	"longitude" DECIMAL NOT NULL,
	"picture" VARCHAR(3000) NOT NULL,
	"laminar_flow" BOOLEAN DEFAULT 'false',
	"turbulent_flow" BOOLEAN DEFAULT 'false',
	"bottle_accessible" BOOLEAN DEFAULT 'false',
	"outdoor" BOOLEAN DEFAULT 'false',
	"indoor" BOOLEAN DEFAULT 'false'
);

CREATE UNIQUE INDEX "fountains_latitude_longitude" ON "public"."fountains"("latitude","longitude");

CREATE TABLE "comments" (
	"id" SERIAL PRIMARY KEY,
	"user_id" BIGINT REFERENCES "users",
	"fountain_id" BIGINT REFERENCES "fountains",
	"body" VARCHAR(500) NOT NULL,
	"likes" BIGINT NOT NULL DEFAULT '0',
	"date" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "ratings" (
	"id" SERIAL PRIMARY KEY,
	"user_id" BIGINT REFERENCES "users",
	"fountain_id" BIGINT REFERENCES "fountains",
	"rating" DECIMAL DEFAULT '0',
	"likes" BIGINT DEFAULT '0',
	UNIQUE ("user_id", "fountain_id")
);

ALTER TABLE "public"."ratings" ALTER COLUMN "rating" SET DEFAULT 0;

CREATE TABLE "replies" (
	"id" SERIAL PRIMARY KEY,
	"user_id" BIGINT REFERENCES "users",
	"comment_id" BIGINT REFERENCES "comments",
	"body" VARCHAR(500) NOT NULL,
	"likes" BIGINT NOT NULL DEFAULT '0',
	"date" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Test data for users
INSERT INTO "users" ("username", "password", "firstname", "lastname", "email", "admin")
VALUES ('admin', '1234', 'admin', 'admin', 'admin@admin.com', 'true');

-- Test data for fountains
INSERT INTO "fountains" ("user_id", "latitude", "longitude", "picture", "turbulent_flow", "bottle_accessible", "indoor")
VALUES ('1', '46.8776563', '-96.7882843', 'images/eda-fountain1.jpeg', 'true', 'true', 'true');
INSERT INTO "fountains" ("user_id", "latitude", "longitude", "picture", "turbulent_flow", "bottle_accessible", "outdoor") 
VALUES('1', '46.9249837', '-96.7882843', 'images/eda-fountain1.jpeg', 'true', 'true', 'true');

-- Some test data for comments
INSERT INTO "comments" ("user_id", "fountain_id", "body")
VALUES ('1', '1', 'This fountain is super cool!');
INSERT INTO "comments" ("user_id", "fountain_id", "body")
VALUES ('1', '1', 'WOW!');

-- Test data for ratings
INSERT INTO "ratings" ("user_id", "fountain_id", "rating")
VALUES ('1', '1', '4.9');



-- @see https://github.com/graphile/postgraphile/blob/886f8752f03d3fa05bdbdd97eeabb153a4d0343e/resources/watch-fixtures.sql

-- Adds the functionality for PostGraphile to watch the database for schema
-- changes. This script is idempotent, you can run it as many times as you
-- would like.

-- Drop the `postgraphile_watch` schema and all of its dependant objects
-- including the event trigger function and the event trigger itself. We will
-- recreate those objects in this script.
drop schema if exists postgraphile_watch cascade;

-- Create a schema for the PostGraphile watch functionality. This schema will
-- hold things like trigger functions that are used to implement schema
-- watching.
create schema postgraphile_watch;

create function postgraphile_watch.notify_watchers_ddl() returns event_trigger as $$
begin
  perform pg_notify(
    'postgraphile_watch',
    json_build_object(
      'type',
      'ddl',
      'payload',
      (select json_agg(json_build_object('schema', schema_name, 'command', command_tag)) from pg_event_trigger_ddl_commands() as x)
    )::text
  );
end;
$$ language plpgsql;

create function postgraphile_watch.notify_watchers_drop() returns event_trigger as $$
begin
  perform pg_notify(
    'postgraphile_watch',
    json_build_object(
      'type',
      'drop',
      'payload',
      (select json_agg(distinct x.schema_name) from pg_event_trigger_dropped_objects() as x)
    )::text
  );
end;
$$ language plpgsql;

-- Create an event trigger which will listen for the completion of all DDL
-- events and report that they happened to PostGraphile. Events are selected by
-- whether or not they modify the static definition of `pg_catalog` that
-- `introspection-query.sql` queries.
create event trigger postgraphile_watch_ddl
  on ddl_command_end
  when tag in (
    -- Ref: https://www.postgresql.org/docs/10/static/event-trigger-matrix.html
    'ALTER AGGREGATE',
    'ALTER DOMAIN',
    'ALTER EXTENSION',
    'ALTER FOREIGN TABLE',
    'ALTER FUNCTION',
    'ALTER POLICY',
    'ALTER SCHEMA',
    'ALTER TABLE',
    'ALTER TYPE',
    'ALTER VIEW',
    'COMMENT',
    'CREATE AGGREGATE',
    'CREATE DOMAIN',
    'CREATE EXTENSION',
    'CREATE FOREIGN TABLE',
    'CREATE FUNCTION',
    'CREATE INDEX',
    'CREATE POLICY',
    'CREATE RULE',
    'CREATE SCHEMA',
    'CREATE TABLE',
    'CREATE TABLE AS',
    'CREATE VIEW',
    'DROP AGGREGATE',
    'DROP DOMAIN',
    'DROP EXTENSION',
    'DROP FOREIGN TABLE',
    'DROP FUNCTION',
    'DROP INDEX',
    'DROP OWNED',
    'DROP POLICY',
    'DROP RULE',
    'DROP SCHEMA',
    'DROP TABLE',
    'DROP TYPE',
    'DROP VIEW',
    'GRANT',
    'REVOKE',
    'SELECT INTO'
  )
  execute procedure postgraphile_watch.notify_watchers_ddl();

-- Create an event trigger which will listen for drop events because on drops
-- the DDL method seems to get nothing returned from
-- pg_event_trigger_ddl_commands()
create event trigger postgraphile_watch_drop
  on sql_drop
  execute procedure postgraphile_watch.notify_watchers_drop();
