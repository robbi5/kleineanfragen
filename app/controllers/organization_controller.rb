class OrganizationController < ApplicationController
  before_filter :find_body
  before_filter :find_organization

  def show
    @papers = @organization.papers
              .where(body: @body)
              .where.not(published_at: nil)
              .includes(:body, :paper_originators)
              .order(legislative_term: :desc, published_at: :desc, reference: :desc)
              .page params[:page]
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_organization
    @organization = Organization.friendly.find params[:organization]
  end
end
