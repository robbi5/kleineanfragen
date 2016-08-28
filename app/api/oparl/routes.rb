module OParl
  # move named route methods in own class
  # support _url in addition to _path
  # No longer needed when https://github.com/reprah/grape-route-helpers/issues/2 gets resolved
  class Routes
    class << self
      include GrapeRouteHelpers::NamedRouteMatcher

      def root_url
        Rails.application.routes.url_helpers.oparl_api_url
      end

      alias_method :nrm_method_missing, :method_missing
      def method_missing(method_name, *arguments)
        super unless (m = method_name.to_s.match(/_(url|path)$/))
        method_name = method_name.to_s.gsub(/_url$/, '_path').to_sym

        ## weirdly doesn't work
        # path = nrm_method_missing(name, *arguments)

        route = Grape::API.decorated_routes.detect do |r|
          r.helper_names.include? method_name.to_s
        end

        if !route
          return super
        end

        path = route.send(method_name, *arguments)

        if m[1] == 'url'
          URI.join(root_url, path).to_s
        else
          path
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        !!method_name.to_s.match(/_(url|path)$/) || super
      end
    end
  end
end