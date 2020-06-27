class SearchController < ApplicationController
  PARAMS_TO_CONVERT = %w(table classified body doctype faction pages published_at)
  SUPPORTED_PARAMS = %w(q page sort) + PARAMS_TO_CONVERT
  ALLOWED_SORT_FIELDS = %w(published_at pages full_reference)

  def search
    @query = params[:q].presence
    redirect_to(root_url) && return if @query.blank?

    if PARAMS_TO_CONVERT.map { |key| params.fetch(key, nil) }.reject(&:nil?).size > 0
      query = self.class.params_to_nice_query(params)
      clean_params = search_params.to_h.except(*PARAMS_TO_CONVERT).except(*ActionController::Parameters.always_permitted_parameters)
      redirect_to search_path(params: clean_params.symbolize_keys.merge!({ q: query }))
      return
    end

    redirect_to(search_path(search_params.except(:sort))) && return if params.key?(:sort) && params[:sort].blank?

    search = self.class.parse_query(@query)
    @term = search.term
    @display_term = term_and_advanced_conditions(search.term, search.raw_terms)
    @conditions = search.conditions

    @bodies = Body.all.order(name: :asc).map { |body| OpenStruct.new(name: body.name, state: body.state) }
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
    conditions[:contains_classified_information] = true if terms['classified']
    if terms['body']
      bodyterms = Array.wrap(terms.body).reject(&:blank?).map(&:downcase)
      conditions[:body] = Body.all.select { |body| bodyterms.include? body.state.downcase }.map(&:state)
    end
    if terms['faction']
      factionterms = Array.wrap(terms.faction).reject(&:blank?).map(&:downcase)
      conditions[:faction] = Organization.all.select { |org| factionterms.include? org.slug.downcase }.map(&:slug)
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
    term = EsQueryParser.map_simple_query_string_word(term)

    options =
      {
        where: conditions,
        fields: ['title^10', :contents, :people],
        highlight: {
          tag: '<mark>',
          fields: {
            title: { number_of_fragments: 0 },
            contents: {
              type: 'fvh',
              fragment_size: 250,
              number_of_fragments: 1,
              no_match_size: 250
            }
          }
        },
        aggs: [:contains_table, :contains_classified_information, :body, :doctype, :faction, :pages, :published_at],
        execute: false,
        misspellings: false,
        includes: [:body, :paper_originators, :originator_people, :originator_organizations]
      }.merge(options)

    query = Paper.search(
      term,
      options
    ) do |body|
      ## use simple_query_string
      ## NOT only works when WHITESPACE is enabled: https://github.com/elastic/elasticsearch/issues/9633
      body[:query] = { dis_max: {} }
      body[:query][:dis_max][:queries] = [
        {
          simple_query_string: {
            query: term,
            fields: ['title.analyzed^10', 'contents.analyzed', 'people.analyzed'],
            flags: 'AND|OR|NOT|PHRASE|WHITESPACE',
            default_operator: 'AND',
            analyzer: 'searchkick_search'
          }
        },
        {
          simple_query_string: {
            query: term,
            fields: ['title.analyzed^10', 'contents.analyzed', 'people.analyzed'],
            flags: 'AND|OR|NOT|PHRASE|WHITESPACE',
            default_operator: 'AND',
            analyzer: 'searchkick_search2'
          }
        }
      ]

      ## boost newer papers
      body[:query] = {
        function_score: {
          query: body[:query],
          boost: 1,
          functions: [
            {
              gauss: {
                published_at: {
                  scale: '42d'
                }
              }
            }
          ],
          boost_mode: 'sum'
        }
      }
    end

    query.execute
  end

  def autocomplete
    q = self.class.simple_parse_query(params[:q])
    render json: Paper.search(q[:term], {
      fields: [
        { 'title^1.5' => :text_start },
        { title: :word_start }
      ],
      limit: 5
    }).map(&:autocomplete_data)
  end

  def advanced
    @bodies = Body.all.order(state: :asc)
  end

  def subscribe
    @subscription = Subscription.new
    @subscription.subtype = :search
    @subscription.query = params[:q].presence

    if !Rails.application.config.x.enable_email_subscription
      render :'subscription/disabled', status: :not_implemented
      return
    end
  end

  def opensearch
    response.headers['Content-Type'] = 'application/opensearchdescription+xml; charset=utf-8'
  end

  def self.params_to_nice_query(params)
    q = []
    q << params[:q] if params[:q].present?
    q << 'table:true' if params[:table].present?
    q << 'classified:true' if params[:classified].present?
    if params[:body].present?
      bodyparams = Array.wrap(params[:body]).reject(&:blank?).map(&:downcase)
      states = Body.all.map(&:state).select { |state| bodyparams.include? state.downcase }
      q << 'body:' + states.join(',')
    end
    if params[:doctype].present?
      doctypes = Paper::DOCTYPES.select { |doctype| params[:doctype].include? doctype }
      q << 'doctype:' + doctypes.join(',')
    end
    if params[:faction].present?
      factionparams = Array.wrap(params[:faction]).reject(&:blank?).map(&:downcase)
      factions = Organization.all.map(&:slug).select { |faction| factionparams.include? faction.downcase }
      q << 'faction:' + factions.join(',')
    end
    if params[:pages].present?
      q << 'pages:' + params[:pages].strip
    end
    q.join ' '
  end

  private

  def term_and_advanced_conditions(term, raw_terms)
    terms = []
    if raw_terms['pages']
      terms << 'pages:' + raw_terms['pages'].to_s.strip
    end
    if raw_terms['classified']
      terms << 'classified:' + raw_terms['classified'].to_s.strip
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