# frozen_string_literal: true

module Committee
  module Test
    class SchemaCoverage
      attr_reader :schema

      def initialize(schema)
        raise 'Unsupported schema' unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        @schema = schema
        @covered = {}
      end

      def update_coverage!(path, method, response_status)
        method = method.to_s.downcase
        response_status = response_status.to_s

        @covered[path] ||= {}
        @covered[path][method] ||= {}
        @covered[path][method]['responses'] ||= {}
        @covered[path][method]['responses'][response_status] = true
      end

      # def method_missing(method, *args, &block)
      #   @covered.send(method, *args, &block)
      # end

      def report
        full = {}
        covered_full_paths = []
        uncovered_full_paths = []

        schema.open_api.paths.path.each do |path_name, path_item|
          full[path_name] = {}
          path_item._openapi_all_child_objects.each do |object_name, object|
            next unless object.is_a?(OpenAPIParser::Schemas::Operation)

            method = object_name.split('/').last&.downcase
            next unless method

            full[path_name][method] = {
              # TODO: check coverage on request params/body as well?
              'responses' => object.responses.response.map do |response_status, _|
                response_status = response_status.to_s
                has_covered = @covered.dig(path_name, method, 'responses', response_status) || false
                array_to_update = has_covered ? covered_full_paths : uncovered_full_paths
                array_to_update << [path_name, method, 'responses', response_status].join(' ')
                [response_status, has_covered]
              end.to_h
            }
          end
        end

        {
          full: full,
          covered: covered_full_paths,
          uncovered: uncovered_full_paths,
        }
      end

      def test!
        report = self.report
        raise "Uncovered paths:\n#{report[:uncovered].join("\n")}" unless report[:uncovered].empty?
      end
    end
  end
end

