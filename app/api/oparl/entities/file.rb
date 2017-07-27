module OParl
  module Entities
    # file is currently a paper too, until we support multiple files per paper.
    class File < Grape::Entity
      expose(:id) { |paper| OParl::Routes.oparl_v1_body_term_paper_file_url(body: paper.body.key, term: paper.legislative_term, paper: paper.reference, file: 1) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/File' }

      with_options(unless: lambda { |obj, _| obj.deleted? }) do
        expose(:paper, if: { type: :file_full }) do |paper|
          [
            OParl::Routes.oparl_v1_body_term_paper_url(body: paper.body.key, term: paper.legislative_term, paper: paper.reference)
          ]
        end

        expose(:name) { |paper| paper.title }
        expose(:date) { |paper| (paper.pdf_last_modified || paper.published_at).to_date }

        expose(:fileName) { |paper| "#{paper.body.key}-#{paper.legislative_term}-#{paper.reference}.pdf" }
        expose(:mimeType) { |_| 'application/pdf' }

        expose(:derivativeFile) do |paper|
          [
            OParl::Routes.oparl_v1_body_term_paper_file_url(body: paper.body.key, term: paper.legislative_term, paper: paper.reference, file: 2)
          ]
        end

        expose(:accessUrl) { |paper| paper.public_url }
        expose(:downloadUrl) { |paper| paper.download_url }

        expose(:web) { |paper| Rails.application.routes.url_helpers.paper_pdf_viewer_url(body: paper.body.slug, legislative_term: paper.legislative_term, paper: paper) } # equivalent in html
      end

      expose(:created) { |obj| [obj.created_at, obj.pdf_last_modified].min.iso8601 }
      expose(:modified) { |obj| (obj.deleted_at || obj.pdf_last_modified).iso8601 }
      expose(:deleted) { |obj| obj.deleted? }
    end
  end
end