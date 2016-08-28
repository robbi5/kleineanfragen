#
# Pagination modeled after OParl Spec.
# Loosly based on grape-kaminari
#
module OParl
  module Pagination
    def self.included(base)
      base.class_eval do
        helpers do
          def paginate(collection)
            collection.page(params[:page]).per(params[:limit]).tap do |data|
              present :pagination, {
                totalElements: data.total_count,
                elementsPerPage: data.limit_value,
                currentPage: data.current_page,
                totalPages: data.total_pages
              }, {}

              links = {}
              links[:prev] = current_url(params: { page: data.prev_page }) unless data.prev_page.nil?
              links[:next] = current_url(params: { page: data.next_page }) unless data.next_page.nil?
              present :links, links, {}
            end
          end
        end

        def self.paginate(options = {})
          options.reverse_merge!(
            per_page: ::Kaminari.config.default_per_page || 25,
            max_per_page: ::Kaminari.config.max_per_page || 100,
          )
          params do
            optional :page,  type: Integer, default: 1,
                             desc: 'Page offset to fetch.'
            optional :limit, type: Integer, default: options[:per_page],
                             desc: 'Number of results to return per page.',
                             values: (0..(options[:max_per_page].to_i))
          end
        end
      end
    end
  end
end