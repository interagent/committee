# frozen_string_literal: true

module Committee
  module Drivers
    module HyperSchema
      class Schema < ::Committee::Drivers::Schema
        # A link back to the derivative instance of Committee::Drivers::Driver
        # that create this schema.
        attr_accessor :driver

        attr_accessor :routes

        attr_reader :validator_option

        def build_router(options)
          @validator_option = Committee::SchemaValidator::Option.new(options, self, :hyper_schema)
          Committee::SchemaValidator::HyperSchema::Router.new(self, @validator_option)
        end
      end
    end
  end
end
