# Committee  [![Travis Status](https://travis-ci.org/interagent/committee.svg)](https://travis-ci.org/interagent/committee)

A collection of middleware to help build services with JSON Schema, OpenAPI 2, OpenAPI 3.

## Supported Ruby Versions

Committee is tested on the following MRI versions:

- 2.3
- 2.4
- 2.5
- 2.6

## Committee::Middleware::RequestValidation

This feature is supported by all of Hyper-Schema, OpenAPI 2, and OpenAPI 3.

``` ruby
use Committee::Middleware::RequestValidation, schema_path: 'docs/schema.json', coerce_date_times: true
```

This piece of middleware validates the parameters of incoming requests to make sure that they're formatted according to the constraints imposed by a particular schema.

Options and their defaults:

| name | Hyper-Schema | OpenAPI 3 | Description |
|-----------:|------------:|------------:| :------------ |
|allow_form_params | true | true | Specifies that input can alternatively be specified as `application/x-www-form-urlencoded` parameters when possible. This won't work for more complex schema validations. |
|allow_get_body | true | false | Allow GET request body, which merge to request parameter. See (#211) |
|allow_query_params | true | true | Specifies that query string parameters will be taken into consideration when doing validation. |
|check_content_type | true | true | Specifies that `Content-Type` should be verified according to JSON Hyper-schema or OpenAPI 3 definition. |
|check_header | true | true | Check header data using JSON Hyper-schema or OpenAPI 3 definition. |
|coerce_date_times | false | true | Convert the string with `"format": "date-time"` parameter to DateTime object. |
|coerce_form_params| false | true | Tries to convert POST data encoded into an `application/x-www-form-urlencoded` body (where values are all strings) into concrete types required by the schema. This works for `null` (empty value), `integer` (numeric value without decimals), `number` (numeric value) and `boolean` ("true" is converted to `true` and "false" to `false`). If coercion is not possible, the original value is passed unchanged to schema validation. |
|coerce_path_params| false | true | The same as `coerce_form_params`, but tries to coerce parameters encoded in a request's URL path. |
|coerce_query_params| false | true  | The same as `coerce_form_params`, but tries to coerce `GET` parameters encoded in a request's query string. |
|coerce_recursive| false | always true | Coerce data in arrays and other nested objects |
|optimistic_json| false | false | Will attempt to parse JSON in the request body even without a `Content-Type: application/json` before falling back to other options. |
|raise| false | false | Raise an exception on error instead of responding with a generic error body. |
|strict| false | false | Puts the middleware into strict mode, meaning that paths which are not defined in the schema will be responded to with a 404 instead of being run. |

Non-boolean options:

| name | allowed object type | Hyper-Schema | OpenAPI 3 | Description |
|-----------:|------------:|------------:|------------:| :------------ |
|error_class| StandardError | supported | supported | Change validation errors from `Committee::ValidationError`). |
|prefix| String | supported | supported | Mounts the middleware to respond at a configured prefix. (e.g. prefix is '/v1' and request path is '/v1/test' use '/test' definition). |
|schema_path| String | supported | supported | Defines the location of the schema file to use for validation. |

Note that Hyper-Schema and OpenAPI 2 get the same defaults for options.

Some examples of use:

``` bash
# missing required parameter
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api"}'
{"id":"invalid_params","message":"Require params: recipient."}

# missing required parameter (should have &query=...)
$ curl -X GET http://localhost:9292/search?category=all
{"id":"invalid_params","message":"Require params: query."}

# contains an unknown parameter
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":"api@heroku.com","sender":"api@heroku.com"}'
{"id":"invalid_params","message":"Unknown params: sender."}

# invalid type
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":7}'
{"id":"invalid_params","message":"Invalid type for key \"recipient\": expected 7 to be [\"string\"]."}

# invalid format (supports date-time, email, uuid)
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":"api@heroku"}'
{"id":"invalid_params","message":"Invalid format for key \"recipient\": expected \"api@heroku\" to be \"email\"."

# invalid pattern
$ curl -X POST http://localhost:9292/apps -H "Content-Type: application/json" -d '{"name":"$#%"}'
{"id":"invalid_params","message":"Invalid pattern for key \"name\": expected $#% to match \"(?-mix:^[a-z][a-z0-9-]{3,30}$)\"."}
```

## Committee::Middleware::Stub

**Note:** This feature is not yet available for OpenAPI 3.

``` ruby
use Committee::Middleware::Stub, schema_path: 'docs/schema.json'
```

This piece of middleware intercepts any routes that are in the JSON Schema, then builds and returns an appropriate response for them.

``` bash
$ curl -X GET http://localhost:9292/apps
[
  {
    "archived_at":"2012-01-01T12:00:00Z",
    "buildpack_provided_description":"Ruby/Rack",
    "created_at":"2012-01-01T12:00:00Z",
    "git_url":"git@heroku.com/example.git",
    "id":"01234567-89ab-cdef-0123-456789abcdef",
    "maintenance":false,
    "name":"example",
    "owner":[
      {
        "email":"username@example.com",
        "id":"01234567-89ab-cdef-0123-456789abcdef"
      }
    ],
    "region":[
      {
        "id":"01234567-89ab-cdef-0123-456789abcdef",
        "name":"us"
      }
    ],
    "released_at":"2012-01-01T12:00:00Z",
    "repo_size":0,
    "slug_size":0,
    "stack":[
      {
        "id":"01234567-89ab-cdef-0123-456789abcdef",
        "name":"cedar"
      }
    ],
    "updated_at":"2012-01-01T12:00:00Z",
    "web_url":"http://example.herokuapp.com"
  }
]
```

### committee-stub

A bundled executable is also available to easily start up a server that will serve the stub for some particular JSON Schema file:

``` bash
committee-stub -p <port> <path to JSON schema>
```

## Committee::Middleware::ResponseValidation

This feature is supported by all of Hyper-Schema, OpenAPI 2, and OpenAPI 3.

``` ruby
use Committee::Middleware::ResponseValidation, schema_path: 'docs/schema.json'
```

This piece of middleware validates the contents of the response received from up the stack for any route that matches the JSON Schema. A hyper-schema link's `targetSchema` property is used to determine what a valid response looks like.

Option values and defaults:

| name | Hyper-Schema | OpenAPI 3 | Description |
|-----------:|------------:|------------:| :------------ |
|raise| false | false | Raise an exception on error instead of responding with a generic error body. |
|validate_success_only| true | false | Also validate non-2xx responses only. |
|ignore_error| false | false | Validate and ignore result even if validation is error. So always return original data. |

No boolean option values:

| name | allowed object type | Hyper-Schema | OpenAPI 3 | Description |
|-----------:|------------:|------------:|------------:| :------------ |
|prefix| String | support | support | Mounts the middleware to respond at a configured prefix. |
|error_class| StandardError | support | support | Specifies the class to use for formatting and outputting validation errors (defaults to `Committee::ValidationError`). |
|error_handler| Proc Object | support | support | A proc which will be called when error occurs. Take an Error instance as first argument. |

Given a simple Sinatra app that responds for an endpoint in an incomplete fashion:

``` ruby
require "committee"
require "sinatra"

use Committee::Middleware::ResponseValidation, schema_path: 'docs/schema.json'

get "/apps" do
  content_type :json
  "[{}]"
end
```

The middleware will raise an error to indicate what the problems are:

``` bash
# missing keys in response
$ curl -X GET http://localhost:9292/apps
{"id":"invalid_response","message":"Missing keys in response: archived_at, buildpack_provided_description, created_at, git_url, id, maintenance, name, owner:email, owner:id, region:id, region:name, released_at, repo_size, slug_size, stack:id, stack:name, updated_at, web_url."}
```

If you want to take log only (for example avoiding false-positive in production), use `ignore_error` and `error_handler` option.

## Validation Errors

Committee will by default respond with a generic error JSON body for validation errors (when the `raise` middleware option is `false`).

Here's an example error to show the default format:

```json
{
  "id":"invalid_response",
  "message":"Missing keys in response: archived_at, buildpack_provided_description, created_at, git_url, id, maintenance, name, owner:email, owner:id, region:id, region:name, released_at, repo_size, slug_size, stack:id, stack:name, updated_at, web_url."
}
```

You can customize this JSON body by setting the `error_class` middleware option. The `error_class` will be instantiated with: `status`, `id`, and `message`.

* `status`: HTTP status code
* `id`: HTTP status name/string
* `message`: error message

Here's an example of a class to format errors according to [JSON API](http://jsonapi.org/format/#errors):

```ruby
module MyAPI
  class ValidationError < Committee::ValidationError
    def error_body
      {
        errors: [
          { status: id, detail: message }
        ]
      }
    end

    def render
      [
        status,
        { "Content-Type" => "application/vnd.api+json" },
        [JSON.generate(error_body)]
      ]
    end
  end
end
```

## Test Assertions

Supported in HyperSchema and OpenAPI 3.

Committee ships with a small set of schema validation test assertions designed to be used along with `rack-test`.

Here's a simple test to demonstrate:

``` ruby
describe Committee::Middleware::Stub do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    Sinatra.new do
      get "/" do
        content_type :json
        JSON.generate({ "foo" => "bar" })
      end
    end
  end

  def committee_options
    @committee_options ||= { schema: Committee::Drivers::load_from_file('docs/schema.json'), prefix: "/v1", validate_success_only: true }
  end

  describe "GET /" do
    it "conforms to schema" do
      assert_schema_conform
    end
   end
end
```

## Using OpenAPI 3

Committee can detect the type of schema (Hyper-Schema, OpenAPI 3, etc.) from the provided file, so there's no need to pass in any additional options:

```ruby
use Committee::Middleware::RequestValidation, schema_path: 'open_api_3/schema.yaml'
```

If you want to select the type manually, pass an `OpenAPI 3` object to the `schema` option manually:

```ruby
open_api = OpenAPIParser.parse(YAML.load_file('open_api_3/schema.yaml'))
schema = Committee::Drivers::OpenAPI3.new.parse(open_api)
use Committee::Middleware::RequestValidation, schema: schema
```

### Limitations of OpenAPI 3 support

* Stub servers are not yet supported, so neither `Committee::Middleware::Stub` or `Committee::Bin::CommitteeStub` are functional.
* Changing `coerce_recursive` isn't supported. This option is always on.

### Upgrading from Committee 2.* to 3.*

Committee 3.* has many breaking changes so we recommend upgrading to the latest release on 2.* and fixing any deprecation errors you see before upgrading to 3.*. The steps would be roughly as follows:

1. Update to the latest 2.* release (usually by modifying the statement in your `Gemfile` and running `bundle update`).
2. Run your test suite and fix any deprecation warnings that appear.
3. Update to the latest 3.* release.
4. Switch to OpenAPI 3 if you'd like to do so.

Important changes are also described below.

### Setting schemas in middleware

Committee 2.* supported setting `schema` to a string or a hash like this:

```ruby
# valid
use Committee::Middleware::RequestValidation, schema: JSON.parse(File.read(...))

# valid
use Committee::Middleware::RequestValidation, schema: {json: 'json_data...'}

# valid
use Committee::Middleware::RequestValidation, schema: 'json string'

```

That usage is no longer supported in 3.* Instead, use either `schema_path` or set a parsed schema object to `schema`:

```ruby
# auto-select Hyper-Schema/OpenAPI 2/OpenAPI 3 from file
use Committee::Middleware::RequestValidation, schema_path: 'docs/schema.json' # using file extension

# auto-select Hyper-Schema/OpenAPI 2/OpenAPI 3 from hash
json = JSON.parse(File.read('docs/schema.json'))
use Committee::Middleware::RequestValidation, schema: Committee::Drivers::load_data(json)

# manually select
json = JSON.parse(File.read(...))
schema = Committee::Drivers::HyperSchema.new.parse(json)
use Committee::Middleware::RequestValidation, schema: schema
```

The auto-select algorithm works roughly like this (so make sure that your file sets one of these attributes correctly):

```ruby
hash = JSON.load(json_path)

# OpenAPI 3 requires the `openapi` key and a version
if hash['openapi']&.start_with?('3.')
  return Committee::Drivers::OpenAPI3.new.parse(hash)

# OpenAPI 2 requires the `swagger` key
elsif hash['swagger'] == '2.0'
  return Committee::Drivers::OpenAPI2.new.parse(hash)

else
  return Committee::Drivers::HyperSchema.new.parse(hash)
end
```

### Test assertions

Committee 3.* drops many of the methods that were
previously available from the `Committee::Test::Methods`
mixin.

Use it by defining a `committee_options` method and having
it return a schema and other options you'd like to use:

```ruby
def committee_options
  @committee_options ||= { schema: Committee::Drivers::load_from_file('docs/schema.json'), prefix: "/v1", validate_success_only: true }
end
```

The default assertion option in 2.* was `validate_success_only=true`, but this becomes `validate_success_only=false` in 3.*. For the smoothest possible upgrade, you should set it to `false` in your test suite before upgrading to 3.*.

### Other changes

* `GET` request bodies are ignored in OpenAPI 3 by default. If you want to use them, set the `allow_get_body` option to `true`.

## Development

Run tests with the following:

```
bundle install
bundle exec rake
```

Run a particular test suite or test:

```
bundle exec ruby -Ilib -Itest test/router_test.rb
bundle exec ruby -Ilib -Itest test/router_test.rb -n /prefix/
```

## Release

1. Update the version in `committee.gemspec` as appropriate for [semantic
   versioning](http://semver.org) and add details to `CHANGELOG`.
2. Commit those changes. Use a commit message like `Bump version to 1.2.3`.
3. Run the `release` task:

    ```
    bundle exec rake release
    ```
