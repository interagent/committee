# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      class Router
        def initialize(schema, validator_option)
          @prefix = validator_option.prefix
          @prefix_regexp = /\A#{Regexp.escape(@prefix)}/.freeze if @prefix
          @schema = schema

          @validator_option = validator_option
        end

        def includes?(path)
          !@prefix || path =~ @prefix_regexp
        end

        def includes_request?(request)
          includes?(request.path)
        end

        def find_link(method, path)
          path = path.gsub(@prefix_regexp, "") if @prefix
          link_with_matches = (@schema.routes[method] || []).map do |pattern, link|
            if matches = pattern.match(path)
              # prefer path which has fewer matches (eg. `/pets/dog` than `/pets/{uuid}` for path `/pets/dog` )
              [matches.captures.size, link, Hash[matches.names.zip(matches.captures)]]
            else
              nil
            end
          end.compact.sort_by(&:first).first
          link_with_matches.nil? ? nil : link_with_matches.slice(1, 2)
        end

        def find_request_link(request)
          find_link(request.request_method, request.path_info)
        end

        def build_schema_validator(request)
          Committee::SchemaValidator::HyperSchema.new(self, request, @validator_option)
        end
      end
    end
  end
end
