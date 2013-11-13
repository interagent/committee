# Committee

A collection of middleware to help build services with JSON Schema.

## Committee::Middleware::RequestValidation

``` ruby
use Committee::Middleware::RequestValidation, schema: File.read(...)
```

This piece of middleware validates the parameters of incoming requests to make sure that they're formatted according to the constraints imposed by a particular schema.

Some examples of use:

``` bash
# missing required parameter
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api"}'
{"id":"invalid_params","error":"Require params: recipient."}

# contains an unknown parameter
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":"api@heroku.com","sender":"api@heroku.com"}'
{"id":"invalid_params","error":"Unknown params: sender."}

# invalid type
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":7}'
{"id":"invalid_params","error":"Invalid type for key \"recipient\": expected 7 to be [\"string\"]."}%

# invalid format (supports date-time, email, uuid)
$ curl -X POST http://localhost:9292/account/app-transfers -H "Content-Type: application/json" -d '{"app":"heroku-api","recipient":"api@heroku"}'
{"id":"invalid_params","error":"Invalid format for key \"recipient\": expected \"api@heroku\" to be \"email\"."

# invalid pattern
$ curl -X POST http://localhost:9292/apps -H "Content-Type: application/json" -d '{"name":"$#%"}'
{"id":"invalid_params","error":"Invalid pattern for key \"name\": expected $#% to match \"(?-mix:^[a-z][a-z0-9-]{3,30}$)\"."}
```

## Committee::Middleware::Stub

``` ruby
use Committee::Middleware::Stub, schema: File.read(...)
```

This piece of middleware intercepts any routes that are in the JSON Schema, then builds and returns an appropriate an appropriate response for them.

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
use Committee::Middleware::ResponseValidation, schema: File.read(...)
```

This piece of middleware validates the contents of the response received from up the stack for any route that matches the JSON Schema.

Given a simple Sinatra app that responds for an endpoint in an incomplete fashion:

``` ruby
require "committee"
require "sinatra"

use Committee::Middleware::ResponseValidation, schema: File.read("...")

get "/apps" do
  content_type :json
  "[{}]"
end
```

The middleware will raise an error to indicate what the problems are:

``` bash
# missing keys in response
$ curl -X GET http://localhost:9292/apps
{"id":"invalid_response","error":"Missing keys in response: archived_at, buildpack_provided_description, created_at, git_url, id, maintenance, name, owner:email, owner:id, region:id, region:name, released_at, repo_size, slug_size, stack:id, stack:name, updated_at, web_url."}
```
