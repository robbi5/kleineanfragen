class PaperController < ApplicationController
  before_filter :find_body
  before_filter :find_legislative_term
  before_filter :find_paper

  def show
  end


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

    redirect_old_slugs
  end

  def find_paper_by_reference(reference)
    puts "find_paper_by_reference #{reference.inspect}"
    @paper = Paper.where(body: @body, legislative_term: @legislative_term, reference: reference).first
    raise ActiveRecord::RecordNotFound if @paper.nil?

    redirect_old_slugs
  end

  def redirect_old_slugs
    if request.path != paper_path(@body, @legislative_term, @paper)
      return redirect_to paper_path(@body, @legislative_term, @paper), :status => :moved_permanently
    end
  end
end
