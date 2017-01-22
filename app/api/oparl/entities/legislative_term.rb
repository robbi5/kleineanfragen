module OParl
  module Entities
    class LegislativeTerm < Grape::Entity
      expose(:id) { |lt| OParl::Routes.oparl_v1_body_term_url(body: lt.body.key, term: lt.term) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/LegislativeTerm' }
      expose(:body, if: { type: :lt_full }) { |lt| OParl::Routes.oparl_v1_body_url(body: lt.body.key) }
      expose(:name) { |lt| "#{lt.term}. Wahlperiode" }
      expose(:startDate, unless: lambda { |lt, _| lt.starts_at.nil? }) { |lt| lt.starts_at }
      expose(:endDate, unless: lambda { |lt, _| lt.ends_at.nil? }) { |lt| lt.ends_at }
      expose(:web) { |lt| Rails.application.routes.url_helpers.legislative_term_url(lt.body, lt.term) }

      expose(:'wikidata:item', unless: lambda { |obj, _| obj.wikidataq.blank? }) { |obj| obj.wikidataq }

      expose(:created, if: { type: :lt_full }) { |lt| lt.created_at.iso8601 }
      expose(:modified, if: { type: :lt_full }) { |lt| lt.updated_at.iso8601 }
    end
  end
end