# frozen_string_literal: true

# Don't Support OpenAPI3

module Committee
  module Bin
    # CommitteeStub internalizes the functionality of bin/committee-stub so
    # that we can test code that would otherwise be difficult to get at in an
    # executable.
    class CommitteeStub
      # Gets a Rack app suitable for use as a stub.
      def get_app(schema, options)
        cache = {}

        raise Committee::OpenAPI3Unsupported.new("Stubs are not yet supported for OpenAPI 3") unless schema.supports_stub?

        Rack::Builder.new {
          unless options[:tolerant]
            use Committee::Middleware::RequestValidation, schema: schema
            use Committee::Middleware::ResponseValidation, schema: schema
          end

          use Committee::Middleware::Stub, cache: cache, schema: schema

          run lambda { |_|
            [404, {}, ["Not found"]]
          }
        }
      end

      # Gets an option parser for command line arguments.
      def get_options_parser
        options = {
          driver: nil,
          help: false,
          port: 9292,
          tolerant: false,
        }

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: rackup [options] [JSON Schema file]"

          opts.separator ""
          opts.separator "Options:"

          # required
          opts.on("-d", "--driver NAME", "name of driver [open_api_2|hyper_schema]") { |name|
            options[:driver] = name.to_sym
          }

          opts.on_tail("-h", "-?", "--help", "Show this message") {
            options[:help] = true
          }

          opts.on("-t", "--tolerant", "don't perform request/response validations") {
            options[:tolerant] = true
          }

          opts.on("-p", "--port PORT", "use PORT (default: 9292)") { |port|
            options[:port] = port
          }
        end
        [options, parser]
      end
    end
  end
end
