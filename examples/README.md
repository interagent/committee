# Example

First, start up the example app.

```
cd examples/
bundle exec ruby app.rb
```

## Basic Stubbed Response

The stub responds to `GET /apps`. All data in the response is generated directly from the JSON Schema.

```
curl -i http://localhost:5000/apps

$ curl -i http://localhost:5000/apps
HTTP/1.1 200 OK
Content-Type: application/json
X-Content-Type-Options: nosniff
Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-04-20)
Date: Wed, 30 Apr 2014 03:04:27 GMT
Content-Length: 83
Connection: Keep-Alive

[
  {
    "id": "01234567-89ab-cdef-0123-456789abcdef",
    "name": "example"
  }
]
```

## Suppressed Stubbed Response

The stub is suppressed in the `POST /apps` handler. The response is generated entirely from within the handler.

```
$ curl -i http://localhost:5000/apps -X POST -H "Content-Type: application/json" -d '{}'
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 104
X-Content-Type-Options: nosniff
Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-04-20)
Date: Wed, 30 Apr 2014 03:28:19 GMT
Connection: Keep-Alive

{
  "id": "9cde79b0-e402-4687-91b5-391b0da20b09",
  "name": "app-9cde79b0-e402-4687-91b5-391b0da20b09"
}
```

## Modified Stubbed Response

The stub generates a response and sends it into the `PATCH apps` handler. The response is modified by the handler according to the incoming parameters, and the request is ultimately servied by the stubbing middleware itself.

```
$ curl -i http://localhost:5000/apps/123 -X PATCH -H "Content-Type: application/json" -d '{"name":"my-app"}'
HTTP/1.1 200 OK
Content-Type: application/json
X-Content-Type-Options: nosniff
Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-04-20)
Date: Wed, 30 Apr 2014 03:30:15 GMT
Content-Length: 70
Connection: Keep-Alive

{
  "id": "01234567-89ab-cdef-0123-456789abcdef",
  "name": "my-app"
}
```
