require_relative './value'
require_relative './object'
require_relative './list'
require_relative './hash'
require_relative './hash_body'

class OpenAPIParser::Parser::Core
  include OpenAPIParser::Parser::Value
  include OpenAPIParser::Parser::Object
  include OpenAPIParser::Parser::List
  include OpenAPIParser::Parser::Hash
  include OpenAPIParser::Parser::HashBody

  def initialize(target_klass)
    @target_klass = target_klass
  end

  private

    attr_reader :target_klass
end
