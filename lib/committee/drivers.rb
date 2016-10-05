module Committee
  module Drivers
    # Gets a driver instance from the specified name. Raises ArgumentError for
    # an unknown driver name.
    def self.driver_from_name(name)
      case name
      when :hyper_schema
        Committee::Drivers::HyperSchema.new
      when :open_api_2
        Committee::Drivers::OpenAPI2.new
      else
        raise ArgumentError, %{Committee: unknown driver "#{name}".}
      end
    end
  end
end
