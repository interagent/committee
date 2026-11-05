# frozen_string_literal: true

module Committee
  module Utils
      # Creates a Hash with indifferent access.
      #
      # (Copied from Sinatra)
    def self.indifferent_hash
      Hash.new { |hash, key| hash[key.to_s] if Symbol === key }
    end

    def self.deep_copy(from)
      if from.is_a?(Hash)
        h = Committee::Utils.indifferent_hash
          from.each_pair do |k, v|
            h[k] = deep_copy(v)
          end
          return h
      end

        if from.is_a?(Array)
          return from.map { |v| deep_copy(v) }
        end

        return from
    end

    STANDARD_HTTP_METHODS = %w[get put post delete options head patch trace query].freeze

    # Standard methods map to lowercase Path Item fields. Others (3.2 additionalOperations)
    # keep their case, since method names are case-sensitive (RFC 9110 §9.1).
    def self.operation_method(method)
      method = method.to_s
      STANDARD_HTTP_METHODS.include?(method.downcase) ? method.downcase : method
    end

    # OpenAPI 3.1 allows `type: [x, "null"]`; returns the first non-null type.
    def self.schema_type(schema)
      type = schema&.type
      type.is_a?(Array) ? (type - ['null']).first : type
    end
  end
end
