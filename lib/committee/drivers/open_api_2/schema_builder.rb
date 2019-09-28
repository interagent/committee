# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI2
      class SchemaBuilder
        def initialize(link_data)
          @link_data = link_data
        end

        private

        LINK_REQUIRED_FIELDS = [
          :name
        ].map(&:to_s).freeze

        attr_accessor :link_data

        def check_required_fields!(param_data)
          LINK_REQUIRED_FIELDS.each do |field|
            if !param_data[field]
              raise ArgumentError,
                    "Committee: no #{field} section in link data."
            end
          end
        end
      end
    end
  end
end

require_relative 'header_schema_builder'
require_relative 'parameter_schema_builder'
