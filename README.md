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

For extracting text from pdfs:

* GraphicsMagick
* Poppler
* Ghostscript

For installation of these, see http://documentcloud.github.io/docsplit/#installation

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

### config/fog.yml

This file contains the connection details to your s3 server/bucket. Test uses the `tmp` folder, so you need no connection to an running s3 compatible storage.

Jobs
----
Jobs are run by ActiveJob / Resque.

You may need to prefix them with `foreman run bundle exec`, so the environment variables are loaded and the correct gems are used.

If you want to see the output on _STDOUT_, use `rake papers:to_stdout papers:import...`.

The typical arguments are [State, LegislativeTerm, Reference]

### Import new papers

    rake 'papers:import_new[BE, 17]'

### Import single paper

    rake papers:to_stdout 'papers:import[BE, 17, 1234]'

### Other

The two import tasks should be enough for daily usage, if you need to (re-)upload the papers to s3 again or extract the text / names, you can use these:

    rake papers:to_stdout 'papers:store[BE, 17, 1234]'
    rake papers:to_stdout 'papers:extract_text[BE, 17, 1234]'
    rake papers:to_stdout 'papers:extract_names[BE, 17, 1234]'