# overriding used es client to force typhoeus.
# default: if patron and typhoeus are in the same application, patron is used
# see: elasticsearch-transport-1.0.15, client.rb#__auto_detect_adapter
Searchkick.client =
  Elasticsearch::Client.new(
    url: ENV.fetch('ELASTICSEARCH_URL', 'localhost:9200'),
    adapter: :typhoeus,
    transport_options: {
      request: {
        timeout: Searchkick.timeout
      }
    }
  )