# OpenAPI Parser
[![Build Status](https://travis-ci.org/ota42y/openapi_parser.svg?branch=master)](https://travis-ci.org/ota42y/openapi_parser)
[![Gem Version](https://badge.fury.io/rb/openapi_parser.svg)](https://badge.fury.io/rb/openapi_parser)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/gems/openapi_parser)
[![Maintainability](https://api.codeclimate.com/v1/badges/62bad4bcb3f691d46487/maintainability)](https://codeclimate.com/github/ota42y/openapi_parser/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/62bad4bcb3f691d46487/test_coverage)](https://codeclimate.com/github/ota42y/openapi_parser/test_coverage)
[![Inch CI](https://inch-ci.org/github/ota42y/openapi_parser.svg?branch=master)](https://inch-ci.org/github/ota42y/openapi_parser)

This is OpenAPI3 parser and validator. 

## Usage

```ruby
root = OpenAPIParser.parse(YAML.load_file('open_api_3/schema.yml'))

# request operation combine path parameters and OpenAPI3's Operation Object
request_operation = root.request_operation(:post, '/validate')

ret = request_operation.validate_request_body('application/json', {"integer" => 1})
# => {"integer" => 1}

# invalid parameter
request_operation.validate_request_body('application/json', {"integer" => '1'})
# => OpenAPIParser::ValidateError: 1 class is String but it's not valid integer in #/paths/~1validate/post/requestBody/content/application~1json/schema/properties/integer

# path parameter
request_operation = root.request_operation(:get, '/path_template_test/1')
request_operation.path_params
# => {"template_name"=>"1"}

# coerce parameter
root = OpenAPIParser.parse(YAML.load_file('open_api_3/schema.yml'), {coerce_value: true, datetime_coerce_class: DateTime}) 
request_operation = root.request_operation(:get, '/string_params_coercer') 
request_operation.validate_request_parameter({'integer_1' => '1', 'datetime_string' => '2016-04-01T16:00:00+09:00'})
# => {"integer_1"=>1, "datetime_string"=>#<DateTime: 2016-04-01T16:00:00+09:00 ((2457480j,25200s,0n),+32400s,2299161j)>
# convert number string to Integer and datetime string to DateTime class

```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install openapi_parser

## Additional features
OpenAPI Parser's validation based on [OpenAPI spec](https://github.com/OAI/OpenAPI-Specification)  
But we support few useful features.

### type validation
We support additional type validation.

|type|format|description|
|---|---|---|
|string|uuid|validate uuid string. But we don't check uuid layout|

## ToDo
- correct schema checker
- more detailed validator

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ota42y/openapi_parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OpenAPIParser project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/openapi_parser/blob/master/CODE_OF_CONDUCT.md).
