# Committee  [![Travis Status](https://travis-ci.org/interagent/committee.svg)](https://travis-ci.org/interagent/committee)

A collection of middleware to help build services with JSON Schema, OpenAPI2, OpenAPI3.

## Supported Ruby Versions

Committee is tested on the following MRI versions:

- 2.3
- 2.4
- 2.5
- 2.6

## Committee::Middleware::RequestValidation
Hyper-Schema and OpenAPI3 support this feature.

``` ruby
use Committee::Middleware::RequestValidation, json_file: 'docs/schema.json', strict: false
```

This piece of middleware validates the parameters of incoming requests to make sure that they're formatted according to the constraints imposed by a particular schema.

Option values and defaults:

| name | Hyper-Schema | OpenAPI3 | Description |
|-----------:|------------:|------------:| :------------ |
|allow_form_params | true | true | Specifies that input can alternatively be specified as `application/x-www-form-urlencoded` parameters when possible. This won't work for more complex schema validations. |
|allow_query_params | true | true | Specifies that query string parameters will be taken into consideration when doing validation. |
|coerce_date_times | false | true | Convert the string with `"format": "date-time"` parameter to DateTime object. |
|coerce_form_params| false | true | Tries to convert POST data encoded into an `application/x-www-form-urlencoded` body (where values are all strings) into concrete types required by the schema. This works for `null` (empty value), `integer` (numeric value without decimals), `number` (numeric value) and `boolean` ("true" is converted to `true` and "false" to `false`). If coercion is not possible, the original value is passed unchanged to schema validation. |
|coerce_query_params| false | true  | The same as `coerce_form_params`, but tries to coerce `GET` parameters encoded in a request's query string. |
|coerce_path_params| false | true | The same as `coerce_form_params`, but tries to coerce parameters encoded in a request's URL path. |
|coerce_recursive| false | always true | Coerce data in arrays and other nested objects |
|check_content_type | true | true | Specifies that `Content-Type` should be verified according to JSON Hyper-schema or OpenAPI3 definition. |
|check_header | true | true | Check header data using JSON Hyper-schema or OpenAPI3 definition. |
|optimistic_json| false | false | Will attempt to parse JSON in the request body even without a `Content-Type: application/json` before falling back to other options. |
|raise| false | false | Raise an exception on error instead of responding with a generic error body. |
|strict| false | false | Puts the middleware into strict mode, meaning that paths which are not defined in the schema will be responded to with a 404 instead of being run. |

No boolean option values:

| name | allowed object type | Hyper-Schema | OpenAPI3 | Description |
|-----------:|------------:|------------:|------------:| :------------ |
|prefix| String | support | support | Mounts the middleware to respond at a configured prefix. (e.g. prefix is '/v1' and request path is '/v1/test' use '/test' definition) |
|error_class| StandardError | support | support | Change validation errors from `Committee::ValidationError`) |

(Hyper-Schema and OpenAPI2 is same default)


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
When you use OpenAPI3, you can't use this feature yet.

``` ruby
use Committee::Middleware::Stub, json_file: 'docs/schema.json'
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
Hyper-Schema and OpenAPI3 support this feature.

``` ruby
use Committee::Middleware::ResponseValidation, json_file: 'docs/schema.json'
```

This piece of middleware validates the contents of the response received from up the stack for any route that matches the JSON Schema. A hyper-schema link's `targetSchema` property is used to determine what a valid response looks like.

Options:

* `error_class`: Specifies the class to use for formatting and outputting validation errors (defaults to `Committee::ValidationError`)
* `prefix`: Mounts the middleware to respond at a configured prefix.
* `raise`: Raise an exception on error instead of responding with a generic error body (defaults to `false`).
* `validate_errors`: Also validate non-2xx responses (defaults to `false`).
* `error_handler`: A proc which will be called when error occurs. Take an Error instance as first argument.

Given a simple Sinatra app that responds for an endpoint in an incomplete fashion:

``` ruby
require "committee"
require "sinatra"

use Committee::Middleware::ResponseValidation, json_file: 'docs/schema.json'

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
        [JSON.generate(error_body)]
      ]
    end
  end
end
```

## Test Assertions
Hyper-Schema and OpenAPI3 support this feature.

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
    json = JSON.parse(File.read("./my-schema.json"))
    json = Committee::Drivers::HyperSchema.new.parse(json)
    
    {schema: schema}
  end

  describe "GET /" do
    it "conforms to schema" do
      assert_schema_conform
    end
   end
end
```

## Using OpenAPI3

Please pass 'openapi_parser' object to committee.
This gem added gem dependency so you can use always

```ruby
open_api = OpenAPIParser.parse(YAML.load_file('open_api_3/schema.yml'))
schema = Committee::Drivers::OpenAPI3.new.parse(open_api)
use Committee::Middleware::RequestValidation, open_api_3: schema
```

### limitations of OpenAPI3 mode

* Not support stub
  * 'Committee::Middleware::Stub' and 'Committee::Bin::CommitteeStub' don't work now.

* Not support coerce_recursive option
  * Always set coerce_recursive=true

## Updater for version 3.x from version 2.x

### Set Committee::Drivers::Schema object for middleware
The schema option support JSON object and Sting and Hash object in version 2.x like this.  

```ruby
# valid
use Committee::Middleware::RequestValidation, schema: JSON.parse(File.read(...))

# valid
use Committee::Middleware::RequestValidation, schema: {json: 'json_data...'}

# valid
use Committee::Middleware::RequestValidation, schema: 'json string'

```

But we don't support version 3.x.  
Because 3.x support other schema and we can't define which parser we use.  
So please wrap Committee::Drivers::Schema like this.   

```ruby
# auto select Hyper-Schema/OpenAPI2 from file
use Committee::Middleware::RequestValidation, json_file: 'docs/schema.json'

# auto select Hyper-Schema/OpenAPI2 from hash
json = JSON.parse(File.read('docs/schema.json'))
use Committee::Middleware::RequestValidation, schema: Committee::Drivers::load_data(json)

# manual select
json = JSON.parse(File.read(...))
schema = Committee::Drivers::HyperSchema.new.parse(json)
use Committee::Middleware::RequestValidation, schema: schema
```

The auto select algorithm like this.

```ruby
hash = JSON.load(json_path)

if hash['swagger'] == '2.0' # OpenAPI2 require swagger key
  return Committee::Drivers::OpenAPI2.new.parse(hash)
else 
  return Committee::Drivers::HyperSchema.new.parse(hash)
end
```

### Change Test Assertions
In committee 3.0 we'll drop many method in method.rb.  
So please overwrite committee_options and return schema data and prefix option.  
This method should return same data in ResponseValidation option.

```ruby
def committee_options
  schema = Committee::Drivers::load_from_json('docs/schema.json')

  {schema: schema, prefix: "/v1"}
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

## Release

1. Update the version in `committee.gemspec` as appropriate for [semantic
   versioning](http://semver.org) and add details to `CHANGELOG`.
2. Commit those changes. Use a commit message like `Bump version to 1.2.3`.
3. Run the `release` task:

    ```
    bundle exec rake release
    ```
