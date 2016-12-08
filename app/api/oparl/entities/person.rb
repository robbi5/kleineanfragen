module OParl
  module Entities
    class Person < Grape::Entity
      expose(:id) { |person| OParl::Routes.oparl_v1_person_url(person: person.slug) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Person' }

      expose(:body) { |person| OParl::Routes.oparl_v1_body_url(body: person.latest_body.key) }

      with_options(unless: lambda { |obj, _| obj.deleted? }) do
        expose :name
      end

      # expose(:web) { |person| Rails.application.routes.url_helpers.person_url(person) } # equivalent in html

      expose(:'wikidata:item', unless: lambda { |obj, _| obj.wikidataq.blank? }) { |obj| obj.wikidataq }

      expose(:created) { |obj| obj.created_at.iso8601 }
      expose(:modified) { |obj| (obj.deleted_at || obj.updated_at).iso8601 }
      expose(:deleted) { |obj| obj.deleted? }
    end
  end
end