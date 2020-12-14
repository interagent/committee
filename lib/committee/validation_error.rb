# frozen_string_literal: true

module Committee
  class ValidationError
    attr_reader :id, :message, :status, :request

    def initialize(status, id, message, request = nil)
      @status = status
      @id = id
      @message = message
      @request = request
    end

    def error_body
      { id: id, message: message }
    end

    def render
      [
        status,
        { "Content-Type" => "application/json" },
        [JSON.generate(error_body)]
      ]
    end
  end
end
