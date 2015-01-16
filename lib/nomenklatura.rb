#
# Simple Nomenklatura (https://github.com/pudo/nomenklatura) API client
# Only for API version 2, so only master and opennames.org
# Based on the https://github.com/pudo/pynomenklatura Python API client
#
module Nomenklatura
  class Client
    include HTTParty
    format :json

    def initialize(options = {})
      options = { api_prefix: '/api/2/' }.merge(options)
      host = options[:host] || ENV['NOMENKLATURA_HOST'] || 'http://opennames.org'
      key = options[:api_key] || ENV['NOMENKLATURA_APIKEY']
      self.class.base_uri(host)
      self.class.default_params(api_key: key)
      if host[-1] == '/' && options[:api_prefix][0] == '/'
        options[:api_prefix] = options[:api_prefix][1..-1]
      end
      @api_prefix = options[:api_prefix]
    end

    def full_path(endpoint)
      endpoint = endpoint[1..-1] if endpoint[0] == '/'
      @api_prefix + endpoint
    end

    def get(path, params)
      self.class.get(full_path(path), query: params)
    end

    def post(path, body)
      body = body.to_json # FIXME: rails
      self.class.post(full_path(path), body: body, headers: { 'Content-Type' => 'application/json' })
    end
  end

  class InvalidRequest < StandardError; end
  class NoMatch < StandardError; end

  class Dataset
    def initialize(name, client_options = {})
      @name = name
      @client = Client.new(client_options)
    end

    # def create(name, label)
    #   data = { name: name, label: label }
    #   @client.post('/datasets', data)
    # end

    def entity_by_name(entityname)
      resp = @client.get(format('/datasets/%s/find', @name), name: entityname)
      if resp.code == 404
        fail NoMatch, resp.parsed_response
      elsif resp.code != 200
        fail InvalidRequest, resp.parsed_response
      end
      Entity.new(@client, resp.parsed_response)
    end

    def create_entity(name, attributes: {}, reviewed: false, invalid: false, canonical: nil, **kw)
      kw.update(
        'name' => name,
        'attributes' => attributes,
        'reviewed' => reviewed,
        'invalid' => invalid,
        'canonical' => canonical,
        'dataset' => @name
      )
      resp = @client.post('/entities', kw)
      if resp.code == 400
        fail InvalidRequest, resp.parsed_response
      end
      Entity.new(@client, resp.parsed_response)
    end

    # PORT from API version 1
    #
    # look for an entity by name, if it doens't exist, create one. return cleaned/same name
    def lookup(name)
      entity = entity_by_name(name).dereference
      return entity.name
    rescue NoMatch
      create_entity(name)
      return name
    end
  end

  class Entity
    def initialize(client, data)
      @client = client
      @data = data
    end

    # FIXME: nicer accessors for ['name', 'invalid', 'reviewed', 'canonical', 'attributes']
    def name; @data.try(:[], 'name'); end
    def invalid; @data.try(:[], 'invalid'); end
    def reviewed; @data.try(:[], 'reviewed'); end
    def attributes; @data.try(:[], 'attributes'); end

    def canonical
      c = @data.try(:[], 'canonical')
      Entity.new(@client, c) unless c.nil?
    end

    def dereference
      return canonical.dereference unless canonical.nil?
      self
    end
  end
end