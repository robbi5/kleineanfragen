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

    # combine namespace and route_param to shorten indentation
    def self.namespace_route(key)
      namespace key do
        route_param key do
          yield
        end
      end
    end

    namespace_route :person do
      before do
        # called @xperson, because @person confuses grape
        @xperson = Person.friendly.find(params[:person])
      end

      get do
        present @xperson, with: OParl::Entities::Person
      end
    end

    namespace_route :body do
      before do
        # called @xbody, because @body confuses grape
        @xbody = Body.where('lower(state) = ?', params[:body]).try(:first)
      end

      namespace_route :organization do
        before do
          @org = @xbody.organizations.where(slug: params[:organization]).first
        end

        get do
          present @org, with: OParl::Entities::Organization, body: @xbody
        end
      end

      get :organizations do
        orgs = @xbody.organizations.order(id: :asc)
        present orgs, root: 'data', with: OParl::Entities::Organization, body: @xbody
        present :links, []
        present :pagination, {}, {}
      end

      get :people do
        people = @xbody.people.order(id: :asc)
        present people, root: 'data', with: OParl::Entities::Person
        present :links, []
        present :pagination, {}, {}
      end

      get :papers do
        papers = @xbody.papers.order(id: :asc).limit(10) # FIXME
        present papers, root: 'data', with: OParl::Entities::Paper
        present :links, []
        present :pagination, {}, {}
      end

      namespace_route :term do
        before do
          @legislative_term = @xbody.legislative_terms.where(term: params[:term]).first
        end

        namespace_route :paper do
          before do
            # called @xpaper, because @paper confuses grape
            @xpaper = @xbody.papers.where(legislative_term: params[:term], reference: params[:paper]).first
          end

          namespace_route :file do
            # file is currently a paper too, until we support multiple files per paper.
            get do
              present @xpaper, with: OParl::Entities::File, type: :file_full
            end
          end

          get do
            present @xpaper, with: OParl::Entities::Paper
          end
        end

        get do
          present @legislative_term, with: OParl::Entities::LegislativeTerm, type: :lt_full
        end
      end

      get :terms do
        terms = @xbody.legislative_terms
        present terms, root: 'data', with: OParl::Entities::LegislativeTerm, type: :lt_full
        present :links, []
        present :pagination, {}, {}
      end

      get do
        present @xbody, with: OParl::Entities::Body
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