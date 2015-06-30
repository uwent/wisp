# README

Run this to restore the production database locally:

```
# untar the tarball first
mysql -u root wisp < mysql_production.sql
```

Recreate local databases:

```
rake db:drop:all db:create:all
```

Run the conversion:

```
mysql2psql
```

Dump the local database:

```
pg_dump -Fc --no-acl --no-owner -h localhost -U wisp wisp_development > wisp_development.dump
```

Upload the .dump file to S3

Restore the dump:

```
heroku pg:backups restore https://s3-us-west-2.amazonaws.com/wisp-db/wisp_development.dump DATABASE_URL --app wisp-staging
```

## TODO

Make changes to my fork of [mysql2postgres](git@github.com:m5rk/mysql2postgres.git)

1. Fix the reader bug

1. Update the version of the pg gem
