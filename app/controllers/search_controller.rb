class SearchController < ApplicationController
  def search
    @query = params[:q].presence
    redirect_to(root_url) && return if @query.blank?

    if params[:table].present? || params[:body].present? || params[:doctype].present?
      query = params_to_nice_query
      redirect_to search_path(params: { q: query })
      return
    end

    search = self.class.parse_query(@query)
    @term = search.term
    @conditions = search.conditions

    @bodies = Body.all.map { |body| OpenStruct.new(name: body.name, state: body.state) }
    @doctypes = Paper::DOCTYPES.map { |doctype| OpenStruct.new(key: doctype, name: t(doctype, scope: [:paper, :doctype]).to_s) }

    @papers = self.class.search_papers(@term, @conditions, page: params[:page], per_page: 10)
  end

  def self.parse_query(query)
    terms = SearchTerms.new(query || '', %w(table body doctype))
    term = terms.query.presence || '*'

    conditions = {}
    conditions[:contains_table] = true if terms['table']
    if terms['body']
      conditions[:body] = Body.all.select { |body| terms.body.include? body.state }.map(&:state)
    end
    if terms['doctype']
      conditions[:doctype] = Paper::DOCTYPES.select { |doctype| terms.doctype.include? doctype }
    end

    OpenStruct.new(term: term, conditions: conditions)
  end

  def self.search_papers(term, conditions, options = {})
    options =
      {
        where: conditions,
        fields: ['title^10', :contents],
        highlight: { tag: '<mark>' },
        facets: [:contains_table, :body, :doctype],
        smart_facets: true,
        execute: false,
        misspellings: false
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
                  scale: '4w'
                }
              }
            }
          ],
          score_mode: 'sum'
        }
      }

      # use simple_query_string
      body[:query][:function_score][:query] = {
        dis_max: {
          queries: [
            {
              simple_query_string: {
                fields: ['title.analyzed^10', 'contents.analyzed'],
                query: term,
                flags: 'AND|OR|NOT|PHRASE',
                default_operator: 'AND',
                analyzer: 'searchkick_search'
              }
            },
            {
              simple_query_string: {
                fields: ['title.analyzed^10', 'contents.analyzed'],
                query: term,
                flags: 'AND|OR|NOT|PHRASE',
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
    render json: Paper.search(params[:q], fields: [{ 'title^1.5' => :text_start }, { title: :word_start }], limit: 5).map(&:autocomplete_data)
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
    q.join ' '
  end
end
