# frozen_string_literal: true

module Committee
  module Test
    class SchemaCoverage
      attr_reader :schema

      class << self
        def merge_report(first, second)
          report = first.dup
          second.each do |k, v|
            if v.is_a?(Hash)
              if report[k].nil?
                report[k] = v
              else
                report[k] = merge_report(report[k], v)
              end
            else
              report[k] ||= v
            end
          end
          report
        end

        def flatten_report(report)
          responses = []
          report.each do |path_name, path_coverage|
            path_coverage.each do |method, method_coverage|
              responses_coverage = method_coverage['responses']
              responses_coverage.each do |response_status, is_covered|
                responses << {
                  path: path_name,
                  method: method,
                  status: response_status,
                  is_covered: is_covered,
                }
              end
            end
          end
          {
            responses: responses,
          }
        end
      end

      def initialize(schema)
        raise 'Unsupported schema' unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        @schema = schema
        @covered = {}
      end

      def update_response_coverage!(path, method, response_status)
        method = method.to_s.downcase
        response_status = response_status.to_s

        @covered[path] ||= {}
        @covered[path][method] ||= {}
        @covered[path][method]['responses'] ||= {}
        @covered[path][method]['responses'][response_status] = true
      end

      def report
        report = {}

        schema.open_api.paths.path.each do |path_name, path_item|
          report[path_name] = {}
          path_item._openapi_all_child_objects.each do |object_name, object|
            next unless object.is_a?(OpenAPIParser::Schemas::Operation)

            method = object_name.split('/').last&.downcase
            next unless method

            report[path_name][method] ||= {}

            # TODO: check coverage on request params/body as well?

            report[path_name][method]['responses'] ||= {}
            object.responses.response.each do |response_status, _|
              is_covered = @covered.dig(path_name, method, 'responses', response_status) || false
              report[path_name][method]['responses'][response_status] = is_covered
            end
            if object.responses.default
              is_default_covered = (@covered.dig(path_name, method, 'responses') || {}).any? do |status, is_covered|
                is_covered && !object.responses.response.key?(status)
              end
              report[path_name][method]['responses']['default'] = is_default_covered
            end
          end
        end

        report
      end

      def report_flatten
        self.class.flatten_report(report)
      end
    end
  end
end

