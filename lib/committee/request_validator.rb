module Committee
  class RequestValidator
    attr_accessor :data

    def initialize(link, options = {})
      @link = link
    end

    def call(request)
      check_content_type!(request)
      @data = Committee::RequestUnpacker.new(request).call
      if @link.schema
        valid, errors = @link.schema.validate(@data)
        if !valid
          errors = JsonSchema::SchemaError.aggregate(errors).join("\n")
          raise InvalidRequest, "Invalid request.\n\n#{errors}"
        end
      end
    end

    private

    def check_content_type!(request)
      unless Rack::Mime.match?(@link.enc_type, request.content_type)
        raise Committee::InvalidRequest,
          %{"Content-Type" request header must be set to "#{@link.enc_type}".}
      end
    end
  end
end
