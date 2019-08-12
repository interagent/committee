# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI2
      # Link abstracts an API link specifically for OpenAPI 2.
      class Link
        # The link's input media type. i.e. How requests should be encoded.
        attr_accessor :enc_type

        attr_accessor :href

        # The link's output media type. i.e. How responses should be encoded.
        attr_accessor :media_type

        attr_accessor :method

        # The link's input schema. i.e. How we validate an endpoint's incoming
        # parameters.
        attr_accessor :schema

        attr_accessor :status_success

        # The link's output schema. i.e. How we validate an endpoint's response
        # data.
        attr_accessor :target_schema

        attr_accessor :header_schema

        def rel
          raise "Committee: rel not implemented for OpenAPI"
        end
      end
    end
  end
end
