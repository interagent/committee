# frozen_string_literal: true

module Committee
  class ValidationError
    attr_reader :id, :message, :status

    def initialize(status, id, message)
      @status = status
      @id = id
      @message = message
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
