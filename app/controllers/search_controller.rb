class SearchController < ApplicationController
  def search
    @query = params[:q].presence
    redirect_to(root_url) && return if @query.blank?

    if params[:table].present? ||
       params[:body].present? ||
       params[:doctype].present? ||
       params[:faction].present? ||
       params[:pages].present?
      query = params_to_nice_query
      redirect_to search_path(params: { q: query })
      return
    end

    search = self.class.parse_query(@query)
    @term = search.term
    @display_term = term_and_advanced_conditions(search.term, search.raw_terms)
    @conditions = search.conditions

    @bodies = Body.all.order(state: :asc).map { |body| OpenStruct.new(name: body.name, state: body.state) }
    @factions = Organization.all.order(slug: :asc).map { |faction| OpenStruct.new(name: faction.name, slug: faction.slug) }
    @doctypes = Paper::DOCTYPES.map { |doctype| OpenStruct.new(key: doctype, name: t(doctype, scope: [:paper, :doctype]).to_s) }

    @papers = self.class.search_papers(@term, @conditions, page: params[:page], per_page: 10)
  end

  def self.simple_parse_query(query)
    terms = SearchTerms.new(query || '', %w(table body doctype faction pages))
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

    OpenStruct.new(term: q[:term], conditions: conditions, raw_terms: terms)
  end

  def self.search_papers(term, conditions, options = {})
    options =
      {
        where: conditions,
        fields: ['title^10', :contents],
        highlight: { tag: '<mark>' },
        facets: [:contains_table, :body, :doctype, :faction, :pages],
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
                fields: ['title.analyzed^10', 'contents.analyzed'],
                query: term,
                flags: 'AND|OR|NOT|PHRASE|WHITESPACE',
                default_operator: 'AND',
                analyzer: 'searchkick_search'
              }
            },
            {
              simple_query_string: {
                fields: ['title.analyzed^10', 'contents.analyzed'],
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
    terms.unshift term if term != '*' || terms.size == 0
    terms.join ' '
  end
end
