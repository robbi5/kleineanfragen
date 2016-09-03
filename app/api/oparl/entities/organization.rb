module OParl
  module Entities
    class Organization < Grape::Entity
      expose(:id) { |org, options| OParl::Routes.oparl_v1_body_organization_url(body: options[:body].key, organization: org.slug) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Organization' }

      expose(:body) { |org, options| OParl::Routes.oparl_v1_body_url(body: options[:body].key) }

      with_options(unless: lambda { |obj, _| obj.deleted? }) do
        expose :name
        expose(:organizationType) { |org| org.is_a?(::Ministry) ? 'Ministerium' : 'Fraktion' } # TODO: add type to model

        expose(:web) do |org, options| # equivalent in html
          if org.is_a?(::Ministry)
            Rails.application.routes.url_helpers.ministry_url(options[:body], org)
          else
            Rails.application.routes.url_helpers.organization_url(options[:body], org)
          end
        end
      end

      expose(:created) { |obj| obj.created_at.iso8601 }
      expose(:modified) { |obj| (obj.deleted_at || obj.updated_at).iso8601 }
      expose(:deleted) { |obj| obj.deleted? }
    end
  end
end