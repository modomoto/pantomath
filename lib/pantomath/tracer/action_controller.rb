# frozen_string_literal: true

# Including this module into a contoller enables tracing for that controller.
# If you want to enable the controller tracing for whole project, include this
# module to ApplicationController.
module Pantomath
  module Tracer
    module ActionController

      def self.included(base)
        base.send(:around_action, :trace_request)
      end

      def trace_request
        start_span
        yield
        set_status
      ensure
        close_span
      end

      private
        def start_span
          Pantomath.tracer.start_active_span(
            span_name,
            child_of: tracer_context,
            tags: {
              "span.kind" => "web",
              "http.url" => request.original_url,
              "controller" => controller_name,
              "action_name" => action_name,
            }
          )
        end

        def span_name
          "#{request.method} #{request.original_url}"
        end

        def tracer_context
          Pantomath.tracer.extract(OpenTracing::FORMAT_RACK, request.env)
        end

        def close_span
          active_scope.close if active_scope
        end

        def active_scope
          Pantomath.tracer.scope_manager.active
        end

        def active_span
          Pantomath.tracer.active_span
        end

        def set_status
          active_span.set_tag("http.status", status)
        end

    end
  end
end
