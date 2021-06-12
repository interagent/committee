# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.4.0] - 2021-06-12
- Please read [4.4.0.rc1] section


## [4.4.0.rc1] - 2021-05-31
- We refactoring request unpacker so please check and feedback if we add bug or break backward compatibility.
- Please set `query_hash_key` like `rack.request.query_hash` bacause will break backward compatibility on 5.0.0. If you doesn't access `rack.request.query_hash`, we recoomennded set `committee.query_hash` (default value in 5.0.0)


### Added

- Test Assertions: assert HTTP status code explicitly. (#302)
- Support Ruby 3.0.1. (#308)

### Fixed
- avoid overwriting query hash (#310)
- save path parameter to other key (#318)
- request unpacker refactoring (#321)
- save request params to other key (#322)

## [4.3.0] - 2020-12-23

### Added

- support API coverage. (#297)
- add request to validation error. (#295)

### Changed
- Improve deprecation messages (#291)

## [4.2.1] - 2020-11-07

### Changed

- Hold original exception only openapi3. (#281)
- Make check for complex JSON types more strict. (#287)
- Put deprecation warning together in one line. (#288)

## [4.2.0] - 2020-08-26

### Changed

- Dose not suppress application error. (#279)

## [4.1.0] - 2020-06-27

### Fixed

- Parse response body as JSON only when applicable. (#273)

## [4.0.0] - 2020-05-14

### Added

- Support Ruby 2.7.x. (#254)
- Support OpenAPI 3 remote $ref. (#266)

### Removed

- Drop Ruby 2.3.x.

## [3.3.0] - 2019-11-16

### Added

- Add a filter for request validation. (#249)
- Add ignore_error option to Committee::Middleware::RequestValidation. (#248)

## [3.2.1] - 2019-10-13

### Changed

- Use openapi_parser 0.6.1 (#246)

### Fixed

- Validate request parameter for POST, PUT, PATCH operations. (#244)

## [3.2.0] - 2019-09-28

### Added

- Add ignore_error option. (#218)

## [3.1.1] - 2019-09-05

### Fixed

- OS3 request validator skip if link does not exist. (#240)

## [3.1.0] - 2019-08-07

### Added

- Add error handler option to Committee::Middleware::RequestValidation. (#230)
- Support request validations by assert_schema_conform. (#227)

### Fixed

- Ensure we catch all OpenAPIParser::OpenAPIError classes when coercing path parameters for OpenAPI 3. (#228)

## [3.0.3] - 2019-06-17

### Changed

- Catch OpenAPIParser::NotExistRequiredKey with RequestValidation. (#225)

## [3.0.2] - 2019-05-15

### Added

- Support OpenAPI 3 patch version. (#223)

## [3.0.1] - 2019-03-18

### Fixed

- Correct use of `filepath` to `schema_path`. (#216)

## [3.0.0] - 2019-01-31

### Added

- Allow GET request body data. (#211)

## [3.0.0.beta3] - 2019-01-25

### Changed

- OpenAPI 3 merge request body to request parameter in GET request. (#210)

## [3.0.0.beta2] - 2019-01-23

### Changed

- Merge 2.4.0 feature (rename `filepath` option to `schema_path` (#191)).

## [3.0.0.beta] - 2019-01-19

### Added

- Support full committee options in OpenAPI3.
- Support check_content_type option for OpenAPI3. (#174)

### Fixed

- Fix bug when non defined link with form content type and coerce option. (#173)

## [3.0.0.alpha] - 2018-12-26

### Added

- OpenAPI 3.0 support. (#164)

### Removed

- Drops support for old versions of Ruby. (#146)

## [2.5.1] - 2019-01-22

### Fixed

- Fix bug in the handling of `pattern` attribute on OpenAPI 2 parameters. (#209)

## [2.5.0] - 2019-01-22

### Added

- Support more parameter validations for OpenAPI 2. (#207)

## [2.4.0] - 2019-01-20

### Added

- Add `error_handler` option. (#152)
- Add `schema_path` option. (#191)
- Add `request_object` and `response_data` to `Committee::Test::Methods`. (#195)
- Add `validate_success_only` option. (#199)

### Changed

- Prefer path with fewest slugs when a request may route to resolve to multiple. (#160)

### Deprecated

- Deprecate many methods in `Committee::Test::Methods`. (#157)
- Deprecated `validate_errors` option in favor of `validate_success_only`. (#187)

### Fixed

- Fix bug when using `coerce_recursive` in request parameters. (#162)

## [2.3.0] - 2018-11-15

### Security

- Update minimum Rack dependencies to mitigate CVE-2018-16471. (#155)

### Deprecated

- Deprecate use of `JsonSchema::Schema` object. (#147)

## [2.2.1] - 2018-09-20

### Added

- Add numeric response status support for openapi 2. (#141)

## [2.2.0] - 2018-09-06

### Added

- Add support for `multipart/form-data` when processing requests. (#127)

## [2.1.1] - 2018-08-04

### Fixed

- Fix the `committee-stub` bin so that it runs if installed as a gem. (#127)

## [2.1.0] - 2017-03-26

### Added

- Support validating header schemas in OpenAPI 2. (#122)

## [2.0.1] - 2017-02-27

### Added

- Support either a string *or* an integer for status code responses. (#125)

## [2.0.0] - 2017-09-05

### Added

- Add support for OpenAPI 2.0.
- Add support for coercing types in form bodies (default on for OpenAPI 2.0).
- Add `committee.response_schema` env key.
- Add sample generators for schemas that are arrays or have enums.
- Add `coerce_date_times` option to turn strings into time objects.
- Add `coerce_recursive` option to disable recursive coercion.

### Changed

- Required that a driver name be passed to `committee-stub` executable.
- Recurse into arrays and objects by default when coercing parameters.
- Raise `Committee::NotFound` with more meaningful error message.

## [1.15.0] - 2016-09-13

### Added

- Add the `coerce_query_params` option to allow queries with basic types to be checked against a schema/

[Unreleased]: https://github.com/interagent/committee/compare/v4.4.0...HEAD
[4.4.0]: https://github.com/interagent/committee/compare/v4.4.0.rc1...v4.4.0
[4.4.0.rc1]: https://github.com/interagent/committee/compare/v4.3.0...v4.4.0.cr1
[4.3.0]: https://github.com/interagent/committee/compare/v4.2.1...v4.3.0
[4.2.1]: https://github.com/interagent/committee/compare/v4.2.0...v4.2.1
[4.2.0]: https://github.com/interagent/committee/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/interagent/committee/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/interagent/committee/compare/v3.3.0...v4.0.0
[3.3.0]: https://github.com/interagent/committee/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/interagent/committee/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/interagent/committee/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/interagent/committee/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/interagent/committee/compare/v3.0.3...v3.1.0
[3.0.3]: https://github.com/interagent/committee/compare/v3.0.2...v3.0.3
[3.0.2]: https://github.com/interagent/committee/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/interagent/committee/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/interagent/committee/compare/v3.0.0.beta3...v3.0.0
[3.0.0.beta3]: https://github.com/interagent/committee/compare/v3.0.0.beta2...v3.0.0.beta3
[3.0.0.beta2]: https://github.com/interagent/committee/compare/v3.0.0.beta...v3.0.0.beta2
[3.0.0.beta]: https://github.com/interagent/committee/compare/v3.0.0.alpha...v3.0.0.beta
[3.0.0.alpha]: https://github.com/interagent/committee/compare/v2.5.1...v3.0.0.alpha
[2.5.1]: https://github.com/interagent/committee/compare/v2.5.0...v2.5.1
[2.5.0]: https://github.com/interagent/committee/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/interagent/committee/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/interagent/committee/compare/v2.2.1...v2.3.0
[2.2.1]: https://github.com/interagent/committee/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/interagent/committee/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/interagent/committee/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/interagent/committee/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/interagent/committee/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/interagent/committee/compare/v1.15.0...v2.0.0
[1.15.0]: https://github.com/interagent/committee/compare/v1.14.1...v1.15.0
