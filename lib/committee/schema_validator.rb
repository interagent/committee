# frozen_string_literal: true

class Committee::SchemaValidator
  class << self
    def request_media_type(request)
      request.content_type.to_s.split(";").first.to_s
    end

    # @param [String] prefix
    # @return [Regexp]
    def build_prefix_regexp(prefix)
      return nil unless prefix

      /\A#{Regexp.escape(prefix)}/.freeze
    end
  end
end
