#
# Implementation of OParl 1.0 for kleineAnfragen
# Spec: https://oparl.org/spezifikation/
#
module OParl
  class API < Grape::API
    version 'v1', using: :path, cascade: false
    prefix :oparl
    content_type :json, 'application/json; charset=utf-8'
    format :json
    default_format :json

    namespace :body do
      route_param :body do
        before do
          # called @xbody, because @body confuses grape
          @xbody = Body.where('lower(state) = ?', params[:body]).try(:first)
        end

        namespace :organization do
          route_param :organization do
            before do
              @org = @xbody.organizations.where(slug: params[:organization]).first
            end

            get do
              present @org, with: OParl::Entities::Organization, type: :org_full, body: @xbody
            end
          end
        end

        get :organizations do
          orgs = @xbody.organizations.order(id: :asc)
          present orgs, root: 'data', with: OParl::Entities::Organization, type: :org_full, body: @xbody
          present :links, []
          present :pagination, {}, {}
        end

        get :people do
          # get /body/:body/people
        end

        get :papers do
          # get /body/:body/papers
        end

        namespace :term do
          route_param :term do
            before do
              @legislative_term = @xbody.legislative_terms.where(term: params[:term]).first
            end

            get do
              present @legislative_term, with: OParl::Entities::LegislativeTerm, type: :lt_full
            end
          end
        end

        get :terms do
          terms = @xbody.legislative_terms
          present terms, root: 'data', with: OParl::Entities::LegislativeTerm, type: :lt_full
          present :links, []
          present :pagination, {}, {}
        end

        get do
          present @xbody, with: OParl::Entities::Body, type: :body_full
        end
      end
    end

    get :bodies do
      bodies = Body.order(state: :asc).all
      present bodies, root: 'data', with: OParl::Entities::Body
      present :links, []
      present :pagination, {}, {}
    end

    get '/', as: :oparl_v1_system do
      sys = {
        contact: Rails.application.config.x.email_support
      }
      present sys, with: OParl::Entities::System
    end

    # 404 handler
    route :any, '*path', as: :oparl_v1_catchall do
      error! 'Not Found', 404
    end
  end
end