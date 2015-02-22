kleineAnfragen.
===============

Liberating *kleine Anfragen* from *Parlamentsdokumentationssysteme*.

Development
-----------

For a simple and quick development environment, [fig](http://fig.sh) is used. Install [docker](https://docs.docker.com/installation/) and [fig](http://www.fig.sh/install.html), then run:

    fig up

Fig downloads the required services (postgres, elasticsearch, redis, ...) as docker containers and links them with the app.
If you want to look into postgres or elasticsearch, uncomment the `ports` section in `fig.yml`.

You may be required to execute database migrations. Try this:

    fig run web rake db:migrate
    fig run web rake db:seed

To get a rails console, run:

    fig run web rails c

### Normalizing Names with Nomenklatura

For normalizing names of people, parties and ministries, we use [Nomenklatura](https://github.com/pudo/nomenklatura).

If you want to use nomenklatura while developing, you need to edit fig.yml:
* Uncomment the nomenklatura link
* the `NOMENKLATURA_` environment variables
* the whole nomenklatura image
* set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to those of a [new Github OAuth application](https://github.com/settings/applications/new).

After your next `fig up` login to your nomenklatura instance (reachable at http://localhost:8080) and get the API key from the _profile_ link. Insert it into fig.yml.

kleineAnfragen needs multiple Datasets with the following identifiers that must be created in Nomenklatura:

* `ka-parties`
* `ka-people-XX` (replace XX with a two letter state)
* `ka-ministries-XX` (replace XX with a two letter state)

Dependencies
------------

* ruby 2.1.5
* postgres
* elasticsearch (for search)
* redis (for resque)
* nodejs (for asset compiling)
* [tika](http://tika.apache.org) (for extracting text from pdfs)
* [Nomenklatura](https://github.com/pudo/nomenklatura) (for normalization of people names, ministries and parties)
* Poppler / pdftoppm (for thumbnailing)
* [image_optim binaries](https://github.com/toy/image_optim#binaries-installation) (for compressing thumbnails)

Configuration
-------------

* `config/application.rb`

	Please change the `config.x.user_agent` to your own email address.

* `.env`

	In development, the environment variables are set in `fig.yml`. For development without fig (or production), create `.env` and fill it with these:

	    export DATABASE_URL="postgres://user:pass@localhost/kleineanfragen"
	    export ELASTICSEARCH_URL="http://127.0.0.1:9200/"
	    export SECRET_KEY_BASE="FIXME"
	    export S3_ACCESS_KEY="FIXME"
	    export S3_SECRET_KEY="FIXME"
	    export REDIS_URL="redis://localhost:6379"
	    export TIKA_SERVER_URL="http://localhost:9998/tika"
	    export NOMENKLATURA_HOST="http://localhost:9000"
	    export NOMENKLATURA_APIKEY="FIXME"

* `config/fog.yml`

	This file contains the connection details to your s3 server/bucket. Test uses the `tmp` folder, so you don't need a connection to a running s3 compatible storage.

Jobs
----
Jobs are run by ActiveJob / Resque.

You may need to prefix them with `bundle exec`, so the correct gems are used.

The typical arguments are `[State, LegislativeTerm, Reference]`

* Import new papers

  ```
  rake 'papers:import_new[BE, 17]'
  ```


* Import single paper

  ```
  rake 'papers:import[BE, 17, 1234]'
  ```


* Other

  The two import tasks should be enough for daily usage, if you need to (re-)upload the papers to s3 again or extract the text / names, you can use these:

      rake 'papers:store[BE, 17, 1234]'
      rake 'papers:extract_text[BE, 17, 1234]'
      rake 'papers:extract_originators[BE, 17, 1234]'
      rake 'papers:extract_answerers[BE, 17, 1234]'