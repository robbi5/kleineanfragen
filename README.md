kleineAnfragen.
===============

Collecting *kleine Anfragen* from *Parlamentsdokumentationssystemen* for easy search- and linkability.

**Update 2020-12-31:** This project is dead now, the repository is only meant as an archive.
Please refrain from forking and redeploying, the Parliaments need to do the next step now.
[More Information in German](https://kleineanfragen.de/info/stilllegung).

Development
-----------

For a simple and quick development environment, [docker-compose](https://docs.docker.com/compose/) is used. Install [docker](https://docs.docker.com/installation/) and [docker-compose](https://docs.docker.com/compose/install/), then run:

    docker-compose up

docker-compose downloads the required services (postgres, elasticsearch, redis, ...) as docker containers and links them with the app.
If you want to look into postgres or elasticsearch, uncomment the `ports` section in `docker-compose.yml`.

You may be required to execute database migrations. Try this:

    docker-compose run web rails db:migrate
    docker-compose run web rails db:seed

To get a rails console, run:

    docker-compose run web rails c

### Importing papers from the public database dump

If you want to develop with already scraped data, you can use the public available data dumps from the [kleineAnfragen.de data page](https://kleineanfragen.de/info/daten). Download the latest `kleineanfragen-....sql.bz2` from there and put it into `tmp/dump/`.

To begin importing the data, you have to first enter a docker container:

    docker run -v $(pwd)/tmp/dump:/tmp/dump --rm --network kleineanfragen_default -it kleineanfragen_database bash

Inside this one-off throwaway container, import the data with following commands

    bzcat /tmp/dump/kleineanfragen-*.sql.bz2 | psql -h database -U kleineanfragen import
    pg_dump -h database -U kleineanfragen -d import --data-only | psql -h database -U kleineanfragen -d kleineanfragen
    psql -h database -U kleineanfragen import -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;"
    exit

### Normalizing Names with Nomenklatura

For normalizing names of people, parties and ministries, we use [Nomenklatura](https://github.com/pudo/nomenklatura).

If you want to use nomenklatura while developing, you need to edit docker-compose.yml:
* Uncomment the nomenklatura link
* the `NOMENKLATURA_` environment variables
* the whole nomenklatura image
* set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to those of a [new Github OAuth application](https://github.com/settings/applications/new).

After your next `docker-compose up` login to your nomenklatura instance (reachable at http://localhost:8080) and get the API key from the _profile_ link. Insert it into docker-compose.yml.

kleineAnfragen needs multiple Datasets with the following identifiers that must be created in Nomenklatura:

* `ka-parties`
* `ka-people-XX` (replace XX with a two letter state)
* `ka-ministries-XX` (replace XX with a two letter state)

### Troubleshooting

You just `git pull`ed and now kleineanfragen doesn't start anymore? Try `docker-compose rm web` and `docker-compose build web` — this rebuilds the container that the application is running in.

Dependencies
------------

* ruby 2.5.8
* postgres
* elasticsearch (for search)
* redis (for sidekiq)
* nodejs (for asset compiling)
* [tika](http://tika.apache.org) (for extracting text from pdfs)
* [Nomenklatura](https://github.com/pudo/nomenklatura) (for normalization of people names, ministries and parties)
* Poppler / pdftoppm (for thumbnailing)
* [image_optim binaries](https://github.com/toy/image_optim#binaries-installation) (for compressing thumbnails)
* s3 compatible storage like [s3ninja](http://s3ninja.net) (see `contrib/s3ninja` for the modified dockered version)

Configuration
-------------

* `config/application.rb`

  Please change the `config.x.user_agent` to your own email address.

* `.env`

  In development, the environment variables are set in `docker-compose.yml`. For development without docker-compose (or production), create `.env` and fill it with these:

      export DATABASE_URL="postgres://user:pass@localhost/kleineanfragen"
      export ELASTICSEARCH_URL="http://127.0.0.1:9200/"
      export SECRET_KEY_BASE="FIXME"
      export S3_ACCESS_KEY="FIXME"
      export S3_SECRET_KEY="FIXME"
      export REDIS_URL="redis://localhost:6379"
      export TIKA_SERVER_URL="http://localhost:9998"
      export NOMENKLATURA_HOST="http://localhost:9000"
      export NOMENKLATURA_APIKEY="FIXME"

* `config/fog.yml`

  This file contains the connection details to your s3 server/bucket. Test uses the `tmp` folder, so you don't need a connection to a running s3 compatible storage.

Jobs
----
Jobs are run by ActiveJob / Sidekiq.

You may need to prefix them with `bundle exec`, so the correct gems are used.

The typical arguments are `[State, LegislativeTerm, Reference]`

* Import new papers

  ```
  rails 'papers:import_new[BE, 17]'
  ```


* Import single paper

  ```
  rails 'papers:import[BE, 17, 1234]'
  ```


* Other

  The two import tasks should be enough for daily usage, if you need to (re-)upload the papers to s3 again or extract the text / names, you can use these:

      rails 'papers:store[BE, 17, 1234]'
      rails 'papers:extract_text[BE, 17, 1234]'
      rails 'papers:extract_originators[BE, 17, 1234]'
      rails 'papers:extract_answerers[BE, 17, 1234]'