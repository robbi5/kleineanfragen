module OParl
  module Entities
    class System < Grape::Entity
      expose(:id) { |_| OParl::Routes.oparl_v1_system_url }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/System' }
      expose(:oparlVersion) { |_| 'https://schema.oparl.org/1.0/' }
      expose(:body) { |_| OParl::Routes.oparl_v1_bodies_url }
      expose(:name) { |_| 'kleineAnfragen' }
      expose(:contactEmail) { |sys| sys[:contact].match(/(.+)\s<(.+)>/).to_a[1] }
      expose(:contactName) { |sys| sys[:contact].match(/(.+)\s<(.+)>/).to_a[2] }
      expose(:website) { |_| Rails.application.routes.url_helpers.root_url }
      expose(:product) { |_| 'https://github.com/robbi5/kleineanfragen' }

      expose(:created) { |_| '2016-08-22' }
      expose(:modified) { |obj| '2016-08-22' }
    end
  end
end