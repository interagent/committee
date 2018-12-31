class Committee::SchemaValidator
  class << self
    def request_media_type(request)
      request.content_type.to_s.split(";").first.to_s
    end
  end
end
