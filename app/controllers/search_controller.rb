class SearchController < ApplicationController
  PARAMS_TO_CONVERT = %w(table body doctype faction pages published_at)
  SUPPORTED_PARAMS = %w(q page sort) + PARAMS_TO_CONVERT
  ALLOWED_SORT_FIELDS = %w(published_at pages full_reference)

  def search
    @query = params[:q].presence
    redirect_to(root_url) && return if @query.blank?

    if params.any? { |param, _v| PARAMS_TO_CONVERT.include? param }
      query = params_to_nice_query
      clean_params = search_params.to_h.except(*PARAMS_TO_CONVERT).except(*ActionController::Parameters.always_permitted_parameters)
      redirect_to search_path(params: clean_params.symbolize_keys.merge!({ q: query }))
      return
    end

    search = self.class.parse_query(@query)
    @term = search.term
    @display_term = term_and_advanced_conditions(search.term, search.raw_terms)
    @conditions = search.conditions

    @bodies = Body.all.order(state: :asc).map { |body| OpenStruct.new(name: body.name, state: body.state) }
    @factions = Organization.all.order(slug: :asc).map { |faction| OpenStruct.new(name: faction.name, slug: faction.slug) }
    @doctypes = Paper::DOCTYPES.map { |doctype| OpenStruct.new(key: doctype, name: t(doctype, scope: [:paper, :doctype]).to_s) }

    options = { page: params[:page], per_page: 10 }
    options[:order] = sort_param unless sort_param.nil?
    @papers = self.class.search_papers(@term, @conditions, options)
  end

  def self.simple_parse_query(query)
    terms = SearchTerms.new(query || '', PARAMS_TO_CONVERT)
    term = terms.query.presence || '*'
    { terms: terms, term: term }
  end

  def self.parse_query(query)
    q = simple_parse_query(query)
    terms = q[:terms]

    conditions = {}
    conditions[:contains_table] = true if terms['table']
    if terms['body']
      conditions[:body] = Body.all.select { |body| terms.body.include? body.state }.map(&:state)
    end
    if terms['faction']
      conditions[:faction] = Organization.all.select { |org| [terms.faction].flatten.include? org.slug }.map(&:slug)
    end
    if terms['doctype']
      conditions[:doctype] = Paper::DOCTYPES.select { |doctype| terms.doctype.include? doctype }
    end
    if terms['pages']
      conditions[:pages] = EsQueryParser.convert_range(terms.pages)
    end
    if terms['published_at']
      conditions[:published_at] = EsQueryParser.convert_date_range(terms.published_at)
    end

    OpenStruct.new(term: q[:term], conditions: conditions, raw_terms: terms)
  end

  def self.search_papers(term, conditions, options = {})
    options =
      {
        where: conditions,
        fields: ['title^10', :contents, :people],
        highlight: { tag: '<mark>' },
        facets: [:contains_table, :body, :doctype, :faction, :pages, :published_at],
        smart_facets: true,
        execute: false,
        misspellings: false,
        include: [:body, :paper_originators]
      }.merge(options)

    query = Paper.search(
      term,
      options
    ) do |body|
      # boost newer papers
      body[:query] = {
        function_score: {
          query: body[:query],
          functions: [
            { boost_factor: 1 },
            {
              gauss: {
                published_at: {
                  scale: '6w'
                }
              }
            }
          ],
          score_mode: 'sum'
        }
      }

      # use simple_query_string
      # NOT only works when WHITESPACE is enabled: https://github.com/elastic/elasticsearch/issues/9633
      body[:query][:function_score][:query] = {
        dis_max: {
          queries: [
            {
              simple_query_string: {
                fields: ['title.analyzed^10', 'contents.analyzed', 'people.analyzed'],
                query: term,
                flags: 'AND|OR|NOT|PHRASE|WHITESPACE',
                default_operator: 'AND',
                analyzer: 'searchkick_search'
              }
            },
            {
              simple_query_string: {
                fields: ['title.analyzed^10', 'contents.analyzed', 'people.analyzed'],
                query: term,
                flags: 'AND|OR|NOT|PHRASE|WHITESPACE',
                default_operator: 'AND',
                analyzer: 'searchkick_search2'
              }
            }
          ]
        }
      }

      body[:highlight][:fields]['title.analyzed'][:number_of_fragments] = 0
      body[:highlight][:fields]['contents.analyzed'] = {
        type: 'fvh',
        fragment_size: 250,
        number_of_fragments: 1,
        no_match_size: 250
      }
    end

    query.execute
  end

  def autocomplete
    q = self.class.simple_parse_query(params[:q])
    render json: Paper.search(q[:term], fields: [{ 'title^1.5' => :text_start }, { title: :word_start }], limit: 5).map(&:autocomplete_data)
  end

  def advanced
    @bodies = Body.all.order(state: :asc)
  end

  def subscribe
    @subscription = Subscription.new
    @subscription.subtype = :search
    @subscription.query = params[:q].presence
  end

  def opensearch
    response.headers['Content-Type'] = 'application/opensearchdescription+xml; charset=utf-8'
  end

  private

  def params_to_nice_query
    q = []
    q << params[:q] if params[:q].present?
    q << 'table:true' if params[:table].present?
    if params[:body].present? && !params[:body].include?('')
      states = Body.all.map(&:state).select { |state| params[:body].include? state }
      q << 'body:' + states.join(',')
    end
    if params[:doctype].present?
      doctypes = Paper::DOCTYPES.select { |doctype| params[:doctype].include? doctype }
      q << 'doctype:' + doctypes.join(',')
    end
    if params[:faction].present?
      factions = Organization.all.map(&:slug).select { |faction| params[:faction].include? faction }
      q << 'faction:' + factions.join(',')
    end
    if params[:pages].present?
      q << 'pages:' + params[:pages].strip
    end
    q.join ' '
  end

  def term_and_advanced_conditions(term, raw_terms)
    terms = []
    if raw_terms['pages']
      terms << 'pages:' + raw_terms['pages'].to_s.strip
    end
    if raw_terms['published_at']
      terms << 'published_at:' + raw_terms['published_at'].to_s.strip
    end
    terms.unshift term if term != '*' || terms.size == 0
    terms.join ' '
  end

  def sort_param
    p = params[:sort]
    return nil if p.blank?
    k, v = p.split(':', 3)
    return nil unless ALLOWED_SORT_FIELDS.include? k
    v = { 'desc' => :desc, 'asc' => :asc }[v] || :desc
    { k.to_sym => v }
  end

  def search_params
    params.permit(*SUPPORTED_PARAMS)
  end
end
