module OParl
  module Entities
    class Organization < Grape::Entity
      expose(:id) { |org, options| OParl::Routes.oparl_v1_body_organization_url(body: options[:body].key, organization: org.slug) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Organization' }

      expose(:body, if: { type: :org_full }) { |org, options| OParl::Routes.oparl_v1_body_url(body: options[:body].key) }

      expose :name
      expose(:organizationType) { |_| 'Fraktion' } # TODO: add type to model

      expose(:web) { |org, options| Rails.application.routes.url_helpers.organization_url(options[:body], org) } # equivalent in html

      expose(:created) { |obj| obj.created_at }
      expose(:modified) { |obj| obj.updated_at }
    end
  end
end