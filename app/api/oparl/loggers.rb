module OParl
  module Loggers
   class RequestId < GrapeLogging::Loggers::Base
      def parameters(request, _)
        { request_id: request.env["action_dispatch.request_id"] }
      end
    end

    class Format < GrapeLogging::Loggers::Base
      def parameters(request, _)
        { formats: ['json'] }
      end
    end

    class Controller < GrapeLogging::Loggers::Base
      def parameters(request, _)
        { controller: 'OParl' }
      end
    end
  end
end
