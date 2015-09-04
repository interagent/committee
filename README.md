# Committee

A collection of middleware to help build services with JSON Schema.

## Supported Ruby Versions

Committee is tested on the following MRI versions:

- 1.9.3-p551
- 2.1.6
- 2.2.2

## Committee::Middleware::RequestValidation

``` ruby
use Committee::Middleware::RequestValidation, schema: JSON.parse(File.read(...))
```

This piece of middleware validates the parameters of incoming requests to make sure that they're formatted according to the constraints imposed by a particular schema.

Options:

* `allow_form_params`: Specifies that input can alternatively be specified as `application/x-www-form-urlencoded` parameters when possible. This won't work for more complex schema validations.
* `allow_query_params`: Specifies that query string parameters will be taken into consideration when doing validation (defaults to `true`).
* `check_content_type`: Specifies that `Content-Type` should be verified according to JSON Hyper-schema definition. (defaults to `true`).
* `error_class`: Specifies the class to use for formatting and outputting validation errors (defaults to `Committee::ValidationError`)
* `optimistic_json`: Will attempt to parse JSON in the request body even without a `Content-Type: application/json` before falling back to other options (defaults to `false`).
* `prefix`: Mounts the middleware to respond at a configured prefix.
* `raise`: Raise an exception on error instead of responding with a generic error body (defaults to `false`).
* `strict`: Puts the middleware into strict mode, meaning that paths which are not defined in the schema will be responded to with a 404 instead of being run (default to `false`).

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

``` ruby
use Committee::Middleware::Stub, schema: JSON.parse(File.read(...))
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

``` ruby
use Committee::Middleware::ResponseValidation, schema: JSON.parse(File.read(...))
```

This piece of middleware validates the contents of the response received from up the stack for any route that matches the JSON Schema. A hyper-schema link's `targetSchema` property is used to determine what a valid response looks like.

Options:

* `error_class`: Specifies the class to use for formatting and outputting validation errors (defaults to `Committee::ValidationError`)
* `prefix`: Mounts the middleware to respond at a configured prefix.
* `raise`: Raise an exception on error instead of responding with a generic error body (defaults to `false`).
* `validate_errors`: Also validate non-2xx responses (defaults to `false`).

Given a simple Sinatra app that responds for an endpoint in an incomplete fashion:

``` ruby
require "committee"
require "sinatra"

use Committee::Middleware::ResponseValidation, schema: JSON.parse(File.read("..."))

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
        [MultiJson.encode(error_body)]
      ]
    end
  end
end
```

## Test Assertions

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
        MultiJson.encode({ "foo" => "bar" })
      end
    end
  end

  def schema_path
    "./my-schema.json"
  end

  describe "GET /" do
    it "conforms to schema" do
      assert_schema_conform
    end
   end
end
```

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
