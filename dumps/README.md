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
bundle exec mysql2psql dumps/mysql2psql.yml
```

Dump the local database:

```
pg_dump -Fc --no-acl --no-owner -h localhost -U wisp wisp_development > wisp_development.dump
```

Upload the .dump file to S3 and make it public

Restore the dump:

```
heroku pg:backups restore https://s3-us-west-2.amazonaws.com/wisp-db/wisp_development.dump DATABASE_URL --app wisp-staging
```