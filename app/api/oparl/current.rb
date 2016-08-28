#
# current_url and current_path-helpers for grape / grape-route-helpers
#
module OParl
  module Current
    def self.included(base)
      base.class_eval do
        helpers do
          def current_path(*options)
            options[0] = prepare_params(options[0])
            OParl::Routes.method_missing(current_helper, *options)
          end

          def current_url(*options)
            options[0] = prepare_params(options[0])
            OParl::Routes.method_missing(current_helper.to_s.gsub(/_path$/, '_url').to_sym, *options)
          end

          private

          # find the relevant helper for the current called grape api method
          def current_helper
            droute = GrapeRouteHelpers::DecoratedRoute.new(route)
            version = route.version
            extension = droute.default_extension
            droute.path_helper_name({ version: version, format: extension }).to_sym
          end

          # merge params from namespace (params like :version),
          # route (params like :body), current query string and
          # given options to an params hash that can be given
          # to an path helper
          def prepare_params(options)
            droute = GrapeRouteHelpers::DecoratedRoute.new(route)
            rq = droute.required_helper_segments
            helper_params = params.select { |k,v| rq.include? k }
            query_params = params.reject do |k,v|
              rq.include?(k) || v == route.params[k][:default]
            end
            helper_params.merge({ params: query_params }.deep_merge(options))
          end
        end
      end
    end
  end
end