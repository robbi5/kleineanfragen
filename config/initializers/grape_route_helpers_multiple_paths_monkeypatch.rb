#
# Monkeypatching grape-route-helpers to support multiple routes in one resource
#
# Source:
# https://github.com/reprah/grape-route-helpers/pull/13
#
module GrapeRouteHelpers
  module AllRoutes
    def all_routes
      routes = subclasses.flat_map { |s| s.send(:prepare_routes) }
      routes.uniq do |r|
        if r.path.nil?
          [r.options]
        else
          [r.options, r.path]
        end
      end
    end
  end
end