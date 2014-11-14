kleineAnfragen.
===============

Liberating *kleine Anfragen* from *Parlamentsdokumentationssysteme*.

Dependencies
------------

* ruby 2.1.3
* postgres

For extracting text from pdfs:

* GraphicsMagick
* Poppler
* Ghostscript

For installation of these, see http://documentcloud.github.io/docsplit/#installation

Jobs
----

Currently only one job:

`rails r "FetchPapersBayernJob.new.perform"`