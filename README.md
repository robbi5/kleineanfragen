kleineAnfragen.
===============

Liberating *kleine Anfragen* from *Parlamentsdokumentationssysteme*.

Dependencies
------------

* ruby 2.1.5
* postgres
* elasticsearch (for search)
* redis (for resque)
* nodejs (for asset compiling)

For extracting text from pdfs you can use a server instance of [Tika](http://tika.apache.org) (see [mattfullerton/tika-tesseract-docker](https://github.com/mattfullerton/tika-tesseract-docker)) or install:

* GraphicsMagick, Poppler and Ghostscript

  For installation of these, see http://documentcloud.github.io/docsplit/#installation

* [Nomenklatura](https://github.com/pudo/nomenklatura) Instance

  Used for normalization of people names, ministries and parties.

* Poppler / pdftoppm (for thumbnailing)
* [image_optim binaries](https://github.com/toy/image_optim#binaries-installation)

Configuration
-------------

### config/application.rb
Please change the `config.x.user_agent` to your own email address.

### config/secrets.yml
Just generate a fresh secret_key_base.

### .env

    export DATABASE_URL="postgres://user:pass@localhost/kleineanfragen"
    export ELASTICSEARCH_URL="http://127.0.0.1:9200/"
    export S3_ACCESS_KEY="x"
    export S3_SECRET_KEY="x"
    export NEWRELIC_LICENSE_KEY="x"
    export REDIS_URL="redis://localhost:6379"
    export TIKA_SERVER_URL="http://localhost:9998/tika"
    export NOMENKLATURA_HOST="http://localhost:9000"
    export NOMENKLATURA_APIKEY="x"

### config/fog.yml

This file contains the connection details to your s3 server/bucket. Test uses the `tmp` folder, so you don't need a connection to a running s3 compatible storage.

Development
-----------

For an easy setup of an local development environment, [fig](http://fig.sh) is used. Install fig and run

    fig up

Fig downloads the required services (postgres, elasticsearch, redis, ...) and installs the needed dependencies in a fresh docker container.

Jobs
----
Jobs are run by ActiveJob / Resque.

You may need to prefix them with `foreman run bundle exec`, so the environment variables are loaded and the correct gems are used.

If you want to see the output on _STDOUT_, use `rake papers:to_stdout papers:import...`.

The typical arguments are `[State, LegislativeTerm, Reference]`

### Import new papers

    rake 'papers:import_new[BE, 17]'

### Import single paper

    rake 'papers:import[BE, 17, 1234]'

### Other

The two import tasks should be enough for daily usage, if you need to (re-)upload the papers to s3 again or extract the text / names, you can use these:

    rake 'papers:store[BE, 17, 1234]'
    rake 'papers:extract_text[BE, 17, 1234]'
    rake 'papers:extract_originators[BE, 17, 1234]'
    rake 'papers:extract_answerers[BE, 17, 1234]'