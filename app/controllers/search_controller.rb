class SearchController < ApplicationController
  def search
    @query = params[:q].presence
    redirect_to(root_url) && return if @query.blank?

    if params[:table].present? || params[:body].present? || params[:doctype].present?
      query = params_to_nice_query
      redirect_to search_path(params: { q: query })
      return
    end

    @terms = SearchTerms.new(@query || '', %w(table body doctype))
    @term = @terms.query.presence || '*'
    @conditions = {}
    @conditions[:contains_table] = true if @terms['table']

    @bodies = Body.all.map { |body| OpenStruct.new(name: body.name, state: body.state) }
    if @terms['body']
      @conditions[:body] = @bodies.select { |body| @terms.body.include? body.state }.map(&:state)
    end

    @doctypes = Paper::DOCTYPES.map { |doctype|  OpenStruct.new(key: doctype, name: t(doctype, scope: [:paper, :doctype]).to_s) }
    @conditions[:doctype] = Paper::DOCTYPES.select { |doctype| @terms['doctype'].include? doctype } if @terms['doctype']

    query = Paper.search @term,
                         where: @conditions,
                         fields: ['title^10', :contents],
                         page: params[:page],
                         per_page: 10,
                         highlight: { tag: '<mark>' },
                         facets: [:contains_table, :body, :doctype],
                         smart_facets: true,
                         execute: false,
                         misspellings: false

    # boost newer papers
    unboosted_query = query.body[:query]
    query.body[:query] = {
      function_score: {
        query: unboosted_query,
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

    query.body[:highlight][:fields]['contents.analyzed'] = {
      'type' => 'fvh',
      'fragment_size' => 250,
      'number_of_fragments' => 1,
      'no_match_size' => 250
    }
    @papers = query.execute
  end

  def autocomplete
    render json: Paper.search(params[:q], fields: [{ 'title^1.5' => :text_start }, { title: :word_start }], limit: 5).map(&:autocomplete_data)
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
