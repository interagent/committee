module OpenAPIParser::MediaTypeSelectable
  private

    # select media type by content_type (consider wild card definition)
    # @param [String] content_type
    # @param [Hash{String => OpenAPIParser::Schemas::MediaType}] content
    # @return [OpenAPIParser::Schemas::MediaType, nil]
    def select_media_type_from_content(content_type, content)
      return nil unless content_type
      return nil unless content

      if (media_type = content[content_type])
        return media_type
      end

      # application/json => [application, json]
      splited = content_type.split('/')

      if (media_type = content["#{splited.first}/*"])
        return media_type
      end

      if (media_type = content['*/*'])
        return media_type
      end

      nil
    end
end
