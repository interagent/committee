# frozen_string_literal: true

module Committee
  module Drivers
    module HyperSchema
      class Driver < ::Committee::Drivers::Driver
        def default_coerce_date_times
          false
        end

        # Whether parameters that were form-encoded will be coerced by default.
        def default_coerce_form_params
          false
        end

        def default_allow_get_body
          true
        end

        # Whether parameters in a request's path will be considered and coerced by
        # default.
        def default_path_params
          false
        end

        # Whether parameters in a request's query string will be considered and
        # coerced by default.
        def default_query_params
          false
        end

        def default_validate_success_only
          true
        end

        def name
          :hyper_schema
        end

        # Parses an API schema and builds a set of route definitions for use with
        # Committee.
        #
        # The expected input format is a data hash with keys as strings (as opposed
        # to symbols) like the kind produced by JSON.parse or YAML.load.
        def parse(schema)
          # Really we'd like to only have data hashes passed into drivers these
          # days, but here we handle a JsonSchema::Schema for now to maintain
          # backward compatibility (this library used to be hyper-schema only).
          if schema.is_a?(JsonSchema::Schema)
            hyper_schema = schema
          else
            hyper_schema = JsonSchema.parse!(schema)
            hyper_schema.expand_references!
          end

          schema = Schema.new
          schema.driver = self
          schema.routes = build_routes(hyper_schema)
          schema
        end

        def schema_class
          Committee::Drivers::HyperSchema::Schema
        end

        private

        def build_routes(hyper_schema)
          routes = {}

          hyper_schema.links.each do |link|
            method, href = parse_link(link)
            next unless method

            rx = %r{^#{href}$}
            Committee.log_debug "Created route: #{method} #{href} (regex #{rx})"

            routes[method] ||= []
            routes[method] << [rx, Link.new(link)]
          end

          # recursively iterate through all `properties` subschemas to build a
          # complete routing table
          hyper_schema.properties.each do |_, subschema|
            routes.merge!(build_routes(subschema)) { |_, r1, r2| r1 + r2 }
          end

          routes
        end

        def href_to_regex(href)
          href.gsub(/\{(.*?)\}/, "[^/]+")
        end

        def parse_link(link)
          return nil, nil if !link.method || !link.href
          method = link.method.to_s.upcase
          # /apps/{id} --> /apps/([^/]+)
          href = href_to_regex(link.href)
          [method, href]
        end
      end
    end
  end
end
