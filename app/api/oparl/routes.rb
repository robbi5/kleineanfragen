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
      def method_missing(method_id, *arguments)
        super unless (m = method_id.to_s.match(/_(url|path)$/))

        path = nrm_method_missing(method_id.to_s.gsub(/_url$/, '_path').to_sym, *arguments)

        if m[1] == 'url'
          URI.join(root_url, path).to_s
        else
          path
        end
      end
    end
  end
end