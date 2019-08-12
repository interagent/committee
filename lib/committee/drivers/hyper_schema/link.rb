# frozen_string_literal: true

module Committee
  module Drivers
    module HyperSchema
      # Link abstracts an API link specifically for JSON hyper-schema.
      #
      # For most operations, it's a simple pass through to a
      # JsonSchema::Schema::Link, but implements some exotic behavior in a few
      # places.
      class Link
        def initialize(hyper_schema_link)
          @hyper_schema_link = hyper_schema_link
        end

        # The link's input media type. i.e. How requests should be encoded.
        def enc_type
          hyper_schema_link.enc_type
        end

        def href
          hyper_schema_link.href
        end

        # The link's output media type. i.e. How responses should be encoded.
        def media_type
          hyper_schema_link.media_type
        end

        def method
          hyper_schema_link.method
        end

        # Passes through a link's parent resource. Note that this is *not* part
        # of the Link interface and is here to support a legacy Heroku-ism
        # behavior that allowed a link tagged with rel=instances to imply that a
        # list will be returned.
        def parent
          hyper_schema_link.parent
        end

        def rel
          hyper_schema_link.rel
        end

        # The link's input schema. i.e. How we validate an endpoint's incoming
        # parameters.
        def schema
          hyper_schema_link.schema
        end

        def status_success
          hyper_schema_link.rel == "create" ? 201 : 200
        end

        # The link's output schema. i.e. How we validate an endpoint's response
        # data.
        def target_schema
          hyper_schema_link.target_schema
        end

        private

        attr_accessor :hyper_schema_link
      end
    end
  end
end
