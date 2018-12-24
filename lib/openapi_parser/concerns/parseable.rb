module OpenAPIParser::Parseable # rubocop:disable Metrics/ModuleLength
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    attr_reader :_openapi_attr_values,
                :_openapi_attr_list_objects,
                :_openapi_attr_objects,
                :_openapi_attr_hash_objects,
                :_openapi_attr_hash_body_objects

    # no option support
    def openapi_attr_values(*names)
      names.each { |name| openapi_attr_value(name) }
    end

    def openapi_attr_value(name, options = {})
      @_openapi_attr_values = {} unless defined?(@_openapi_attr_values)

      attr_reader name
      @_openapi_attr_values[name] = options
    end

    # no option support
    def openapi_attr_objects(*names, klass)
      names.each { |name| openapi_attr_object(name, klass) }
    end

    def openapi_attr_object(name, klass, options = {})
      @_openapi_attr_objects = {} unless defined?(@_openapi_attr_objects)

      attr_reader name
      @_openapi_attr_objects[name] = options.merge(klass: klass)
    end

    def openapi_attr_list_object(name, klass, options = {})
      @_openapi_attr_list_objects = {} unless defined?(@_openapi_attr_list_objects)

      attr_reader name
      @_openapi_attr_list_objects[name] = options.merge(klass: klass)
    end

    def openapi_attr_hash_object(name, klass, options = {})
      @_openapi_attr_hash_objects = {} unless defined?(@_openapi_attr_hash_objects)

      attr_reader name
      @_openapi_attr_hash_objects[name] = options.merge(klass: klass)
    end

    def openapi_attr_hash_body_objects(name, klass, options = {})
      @_openapi_attr_hash_body_objects = {} unless defined?(@_openapi_attr_hash_body_objects)

      options[:reject_keys] = options[:reject_keys] ? options[:reject_keys].map(&:to_s) : []

      attr_reader name
      @_openapi_attr_hash_body_objects[name] = options.merge(klass: klass)
    end
  end

  def child_from_reference(reference)
    _openapi_all_child_objects[reference]
  end

  def _openapi_all_child_objects
    @_openapi_all_child_objects ||= {} # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def _add_child_object(object)
    return unless object.kind_of?(OpenAPIParser::Parseable)

    _openapi_all_child_objects[object.object_reference] = object
  end

  def _update_child_object(old, new)
    _openapi_all_child_objects[old.object_reference] = new
  end

  def load_data
    create_attr_values(self.class._openapi_attr_values)

    create_attr_objects(self.class._openapi_attr_objects)
    create_attr_list_objects(self.class._openapi_attr_list_objects)
    create_attr_hash_objects(self.class._openapi_attr_hash_objects)
    create_attr_hash_body_objects(self.class._openapi_attr_hash_body_objects)
  end

  def create_attr_list_objects(settings)
    return unless settings

    settings.each do |variable_name, options|
      ref_name_base = options[:schema_key] || variable_name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      create_attr_list_object(variable_name, raw_schema[ref_name_base.to_s], ref_name_base, klass, allow_reference, allow_data_type)
    end
  end

  def create_attr_hash_objects(settings)
    return unless settings

    settings.each do |variable_name, options|
      ref_name_base = options[:schema_key] || variable_name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      create_attr_hash_object(variable_name, raw_schema[ref_name_base .to_s], ref_name_base, klass, allow_reference, allow_data_type)
    end
  end

  def create_attr_objects(values)
    return unless values

    values.each do |name, options|
      key = options[:schema_key] || name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      obj = create_attr_object(name, key, raw_schema[key.to_s], klass, allow_reference, allow_data_type)
      _add_child_object(obj)
    end
  end

  def create_attr_hash_body_objects(values)
    return unless values

    values.each do |name, options|
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]
      reject_keys = options[:reject_keys]

      create_hash_body_objects(name, raw_schema, klass, allow_reference, allow_data_type, reject_keys)
    end
  end

  def create_attr_values(values)
    return unless values

    values.each do |variable_name, options|
      key = options[:schema_key] || variable_name

      create_variable(variable_name, raw_schema[key.to_s])
    end
  end

  # for responses and paths object
  def create_hash_body_objects(name, schema, klass, allow_reference, allow_data_type, reject_keys)
    unless schema
      create_variable(name, nil)
      return
    end

    object_list = schema.reject { |k, _| reject_keys.include?(k) }.map do |child_name, child_schema|
      [
        child_name.to_s, # support string key only in OpenAPI3
        build_openapi_object(escape_reference(child_name), child_schema, klass, allow_reference, allow_data_type),
      ]
    end

    objects = object_list.to_h
    create_variable(name, objects)
    objects.values.each { |o| _add_child_object(o) }
  end

  # @return [OpenAPIParser::Schemas::Base]
  def create_attr_object(variable_name, ref_name, schema, klass, allow_reference, allow_data_type)
    data = build_openapi_object(ref_name, schema, klass, allow_reference, allow_data_type)
    create_variable(variable_name, data)
    data
  end

  def create_attr_hash_object(variable_name, hash_schema, ref_name_base, klass, allow_reference, allow_data_type)
    data = if hash_schema
             hash_schema.map { |key, s| [key, build_openapi_object([ref_name_base, key], s, klass, allow_reference, allow_data_type)] }.to_h
           else
             nil
           end

    create_variable(variable_name, data)
    data.values.each { |obj| _add_child_object(obj) } if data
  end

  def create_attr_list_object(variable_name, array_schema, ref_name_base, klass, allow_reference, allow_data_type)
    data = if array_schema
             array_schema.map.with_index { |s, idx| build_openapi_object([ref_name_base, idx], s, klass, allow_reference, allow_data_type) }
           else
             nil
           end

    create_variable(variable_name, data)
    data.each { |obj| _add_child_object(obj) } if data
  end

  # create instance variable @variable_name using data
  # @param [String] variable_name
  # @param [Object] data
  def create_variable(variable_name, data)
    instance_variable_set("@#{variable_name}", data)
  end

  # return nil, klass, Reference
  def build_openapi_object(ref_names, schema, klass, allow_reference, allow_data_type)
    return nil unless schema

    if allow_data_type && !check_object_schema?(schema)
      schema
    elsif allow_reference && check_reference_schema?(schema)
      OpenAPIParser::Schemas::Reference.new(build_object_reference(ref_names), self, self.root, schema)
    else
      klass.new(build_object_reference(ref_names), self, self.root, schema)
    end
  end

  # @return Boolean
  def check_reference_schema?(check_schema)
    check_object_schema?(check_schema) && !check_schema['$ref'].nil?
  end

  def check_object_schema?(check_schema)
    check_schema.kind_of?(Hash)
  end

  def escape_reference(str)
    str.to_s.gsub('/', '~1')
  end

  # @return [String]
  def build_object_reference(names)
    names = [names] unless names.kind_of?(Array)
    ref = names.map { |n| escape_reference(n) }.join('/')

    "#{object_reference}/#{ref}"
  end
end
