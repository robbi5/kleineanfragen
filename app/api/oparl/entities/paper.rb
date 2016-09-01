module OParl
  module Entities
    class Paper < Grape::Entity
      expose(:id) { |paper| OParl::Routes.oparl_v1_body_term_paper_url(body: paper.body.key, term: paper.legislative_term, paper: paper.reference) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Paper' }

      expose(:body) { |paper| OParl::Routes.oparl_v1_body_url(body: paper.body.key) }

      with_options(unless: lambda { |obj| obj.deleted? }) do
        expose(:name) { |paper| paper.title }
        expose(:reference) { |paper| paper.full_reference }
        expose(:date) { |paper| paper.published_at }
        expose(:paperType) { |paper| paper.is_answer? ? "Antwort auf #{paper.doctype_human}" : paper.doctype_human }

        expose :mainFile, using: OParl::Entities::File

        expose(:originatorPerson) { |paper| paper.originator_people.map { |person| OParl::Routes.oparl_v1_person_url(person: person.slug) } }
        expose(:underDirectionOf) { |paper| paper.answerer_ministries.map { |ministry| OParl::Routes.oparl_v1_body_organization_url(body: paper.body.key, organization: ministry.slug) } }
        expose(:originatorOrganization) { |paper| paper.originator_organizations.map { |org| OParl::Routes.oparl_v1_body_organization_url(body: paper.body.key, organization: org.slug) } }

        expose(:web) { |paper| Rails.application.routes.url_helpers.paper_url(paper.body, paper.legislative_term, paper) } # equivalent in html
      end

      expose(:created) { |obj| obj.created_at }
      expose(:modified) { |obj| obj.deleted_at || obj.updated_at }
      expose(:deleted) { |obj| obj.deleted? }

      private

      # file is currently the same paper, until we support multiple files per paper.
      def mainFile
        object
      end
    end
  end
end