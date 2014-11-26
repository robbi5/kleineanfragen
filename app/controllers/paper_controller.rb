class PaperController < ApplicationController
  before_filter :find_body, only: [:show, :viewer]
  before_filter :find_legislative_term, only: [:show, :viewer]
  before_filter :find_paper, only: [:show, :viewer]
  before_filter :redirect_old_slugs, only: [:show]

  def show
    if stale?(@paper, public: true)
      respond_to do |format|
        format.html
        format.pdf { redirect_to @paper.url }
      end
    end
  end

  def viewer
    public_url = @paper.public_url
    return redirect_to "https://mozilla.github.io/pdf.js/web/viewer.html?file=#{public_url}" unless @paper.downloaded_at.nil? || public_url.blank?
    render layout: false
  end

  def search
    @term = params[:q]
    redirect_to root_url if @term.blank?

    query = Paper.search @term,
                         fields: ['title^10', :contents],
                         page: params[:page],
                         per_page: 10,
                         highlight: { tag: '<mark>' },
                         execute: false

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
    render json: Paper.search(params[:q], fields: [{ title: :text_start }], limit: 5).map(&:autocomplete_data)
  end

  def recent
    @days = 14
    @papers = Paper.where('published_at >= ?', Date.today - @days.days)
              .order(published_at: :desc, reference: :desc)
              .page(params[:page])
    @recent = @papers.to_a.group_by(&:published_at)
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_legislative_term
    @legislative_term = params[:legislative_term].to_i
  end

  def find_paper
    if params[:paper] =~ /^\d+$/
      return find_paper_by_reference(params[:paper])
    end

    begin
      @paper = Paper.where(body: @body, legislative_term: @legislative_term).friendly.find params[:paper]
    rescue ActiveRecord::RecordNotFound => e
      if params[:paper] =~ /^(\d+)\-/
        return find_paper_by_reference Regexp.last_match[1]
      end
      raise e
    end
  end

  def find_paper_by_reference(reference)
    @paper = Paper.where(body: @body, legislative_term: @legislative_term, reference: reference).first
    fail ActiveRecord::RecordNotFound if @paper.nil?
  end

  def redirect_old_slugs
    canonical_path = paper_path(@body, @legislative_term, @paper, { format: mime_extension(request.format) })
    if request.path != canonical_path
      return redirect_to canonical_path, status: :moved_permanently
    end
  end
end
