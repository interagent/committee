# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [5.4.0] - 2024-06-17

### Changed

- Ensure request body is always rewound [#425](https://github.com/interagent/committee/pull/425)
  - `Rack::Request#POST` no longer rewind, it because removed in rack/rack@42aff22f708123839ba706cbe659d108b47c40c7.

## [5.3.0] - 2024-05-16

### Added

- Add `allow_blank_structures` option [#417](https://github.com/interagent/committee/pull/417)
  - Allow Empty Response Body. supported on Hyper-schema parser but will default to true in next major version.

### Changed

- Rename `parameter_overwite_by_rails_rule` to `parameter_overwrite_by_rails_rule` [#396](https://github.com/interagent/committee/pull/396)
  - You can use old option name but it will be deprecated in next major version.

## [5.2.0] - 2024-05-04
- Error explicitly that OpenAPI 3.1+ isn't supported [#418](https://github.com/interagent/committee/pull/418)

## [5.1.0] - 2024-01-16
- Implement cache in schema loading [#385](https://github.com/interagent/committee/pull/385)
- Upgrade `openapi_parser` dependency to 2.0 [#400](https://github.com/interagent/committee/pull/400)
- Drop support for Ruby 2.6 [#403](https://github.com/interagent/committee/pull/403)

## [5.0.0] - 2023-01-28
- Skip content-type validation in OpenAPI 3 when body is both optional & empty [#355](https://github.com/interagent/committee/pull/355)
  - Support RequestBody.required for OpenAPI 3

## [5.0.0.beta1] - 2023-01-25
- Drop ruby 2.4 and 2.5 [#326](https://github.com/interagent/committee/pull/326)
- Don't validate response for status 304(Not Modified) [#332](https://github.com/interagent/committee/pull/332)
- Allow HEAD method in OpenAPI 3 [#331](https://github.com/interagent/committee/pull/331)
- Support strict response validation [#319](https://github.com/interagent/committee/pull/319)
- Support Psych v4.0.0 [#335](https://github.com/interagent/committee/pull/335)
- Support Http OPTIONS method [#344](https://github.com/interagent/committee/pull/344)
- Add OpenAPI3 strict references option to Committee ([#343](https://github.com/interagent/committee/pull/343)) [#346](https://github.com/interagent/committee/pull/346)
  - When there is a reference objects with no referent, we'll raise error.
- Validate path, query and request parameters separately [#349](https://github.com/interagent/committee/pull/349)
- Change parameter_overwite_by_rails_rule option's default [#374](https://github.com/interagent/committee/pull/374)
- Change query_hash key option's default [#375](https://github.com/interagent/committee/pull/375)
- Change error handler option [#379](https://github.com/interagent/committee/pull/379)
  - error handler take two args (this is deprecation in 4.99.x)
- Change old assert behavior [#380](https://github.com/interagent/committee/pull/380)
  - when we use `assert_schema_conform` we validate response only by default.
  - But we validate request by default
  - This default behavior is deprecation in 4.99.x

## [4.99.0] - 2023-01-28

- Please read [4.4.99.beta1] section

## [4.99.0.beta1] - 2023-01-24
- We add backport parameter overwrite rule [#373](https://github.com/interagent/committee/pull/373)
  - We provide merged parameter for `committee.params` ( `params_key` option)
  - When a parameter of the same name exists in the path/query/request body, it will be overwritten.
  - We we change overwrite rule next version.
  - Please set `parameter_overwite_by_rails_rule=true` for Rails rule (v5.0.0)
    - (high priority) path_hash_key -> request_body_hash -> query_param
  - If you don't want to change, please set false (current rule)
    - (high priority) path_hash_key -> query_param -> request_body_hash
- Support newest ruby version 
  - backport #368


## [4.4.0] - 2021-06-12
- Please read [4.4.0.rc1] section


## [4.4.0.rc1] - 2021-05-31
- We refactoring request unpacker so please check and feedback if we add bug or break backward compatibility.
- Please set `query_hash_key` like `rack.request.query_hash` because will break backward compatibility on 5.0.0. If you doesn't access `rack.request.query_hash`, we recommended set `committee.query_hash` (default value in 5.0.0)


### Added

- Test Assertions: assert HTTP status code explicitly. ([#302](https://github.com/interagent/committee/pull/302))
- Support Ruby 3.0.1. ([#308](https://github.com/interagent/committee/pull/308))

### Fixed
- avoid overwriting query hash ([#310](https://github.com/interagent/committee/pull/310))
- save path parameter to other key ([#318](https://github.com/interagent/committee/pull/318))
- request unpacker refactoring ([#321](https://github.com/interagent/committee/pull/321))
- save request params to other key ([#322](https://github.com/interagent/committee/pull/322))

## [4.3.0] - 2020-12-23

### Added

- support API coverage. ([#297](https://github.com/interagent/committee/pull/297))
- add request to validation error. ([#295](https://github.com/interagent/committee/pull/295))

### Changed
- Improve deprecation messages ([#291](https://github.com/interagent/committee/pull/291))

## [4.2.1] - 2020-11-07

### Changed

- Hold original exception only openapi3. ([#281](https://github.com/interagent/committee/pull/281))
- Make check for complex JSON types more strict. ([#287](https://github.com/interagent/committee/pull/287))
- Put deprecation warning together in one line. ([#288](https://github.com/interagent/committee/pull/288))

## [4.2.0] - 2020-08-26

### Changed

- Does not suppress application error. ([#279](https://github.com/interagent/committee/pull/279))

## [4.1.0] - 2020-06-27

### Fixed

- Parse response body as JSON only when applicable. ([#273](https://github.com/interagent/committee/pull/273))

## [4.0.0] - 2020-05-14

### Added

- Support Ruby 2.7.x. ([#254](https://github.com/interagent/committee/pull/254))
- Support OpenAPI 3 remote $ref. ([#266](https://github.com/interagent/committee/pull/266))

### Removed

- Drop Ruby 2.3.x.

## [3.3.0] - 2019-11-16

### Added

- Add a filter for request validation. ([#249](https://github.com/interagent/committee/pull/249))
- Add ignore_error option to Committee::Middleware::RequestValidation. ([#248](https://github.com/interagent/committee/pull/248))

## [3.2.1] - 2019-10-13

### Changed

- Use openapi_parser 0.6.1 ([#246](https://github.com/interagent/committee/pull/246))

### Fixed

- Validate request parameter for POST, PUT, PATCH operations. ([#244](https://github.com/interagent/committee/pull/244))

## [3.2.0] - 2019-09-28

### Added

- Add ignore_error option. ([#218](https://github.com/interagent/committee/pull/218))

## [3.1.1] - 2019-09-05

### Fixed

- OS3 request validator skip if link does not exist. ([#240](https://github.com/interagent/committee/pull/240))

## [3.1.0] - 2019-08-07

### Added

- Add error handler option to Committee::Middleware::RequestValidation. ([#230](https://github.com/interagent/committee/pull/230))
- Support request validations by assert_schema_conform. ([#227](https://github.com/interagent/committee/pull/227))

### Fixed

- Ensure we catch all OpenAPIParser::OpenAPIError classes when coercing path parameters for OpenAPI 3. ([#228](https://github.com/interagent/committee/pull/228))

## [3.0.3] - 2019-06-17

### Changed

- Catch OpenAPIParser::NotExistRequiredKey with RequestValidation. ([#225](https://github.com/interagent/committee/pull/225))

## [3.0.2] - 2019-05-15

### Added

- Support OpenAPI 3 patch version. ([#223](https://github.com/interagent/committee/pull/223))

## [3.0.1] - 2019-03-18

### Fixed

- Correct use of `filepath` to `schema_path`. ([#216](https://github.com/interagent/committee/pull/216))

## [3.0.0] - 2019-01-31

### Added

- Allow GET request body data. ([#211](https://github.com/interagent/committee/pull/211))

## [3.0.0.beta3] - 2019-01-25

### Changed

- OpenAPI 3 merge request body to request parameter in GET request. ([#210](https://github.com/interagent/committee/pull/210))

## [3.0.0.beta2] - 2019-01-23

### Changed

- Merge 2.4.0 feature (rename `filepath` option to `schema_path` ([#191](https://github.com/interagent/committee/pull/191))).

## [3.0.0.beta] - 2019-01-19

### Added

- Support full committee options in OpenAPI3.
- Support check_content_type option for OpenAPI3. ([#174](https://github.com/interagent/committee/pull/174))

### Fixed

- Fix bug when non defined link with form content type and coerce option. ([#173](https://github.com/interagent/committee/pull/173))

## [3.0.0.alpha] - 2018-12-26

### Added

- OpenAPI 3.0 support. ([#164](https://github.com/interagent/committee/pull/164))

### Removed

- Drops support for old versions of Ruby. ([#146](https://github.com/interagent/committee/pull/146))

## [2.5.1] - 2019-01-22

### Fixed

- Fix bug in the handling of `pattern` attribute on OpenAPI 2 parameters. ([#209](https://github.com/interagent/committee/pull/209))

## [2.5.0] - 2019-01-22

### Added

- Support more parameter validations for OpenAPI 2. ([#207](https://github.com/interagent/committee/pull/207))

## [2.4.0] - 2019-01-20

### Added

- Add `error_handler` option. ([#152](https://github.com/interagent/committee/pull/152))
- Add `schema_path` option. ([#191](https://github.com/interagent/committee/pull/191))
- Add `request_object` and `response_data` to `Committee::Test::Methods`. ([#195](https://github.com/interagent/committee/pull/195))
- Add `validate_success_only` option. ([#199](https://github.com/interagent/committee/pull/199))

### Changed

- Prefer path with fewest slugs when a request may route to resolve to multiple. ([#160](https://github.com/interagent/committee/pull/160))

### Deprecated

- Deprecate many methods in `Committee::Test::Methods`. ([#157](https://github.com/interagent/committee/pull/157))
- Deprecated `validate_errors` option in favor of `validate_success_only`. ([#187](https://github.com/interagent/committee/pull/187))

### Fixed

- Fix bug when using `coerce_recursive` in request parameters. ([#162](https://github.com/interagent/committee/pull/162))

## [2.3.0] - 2018-11-15

### Security

- Update minimum Rack dependencies to mitigate CVE-2018-16471. ([#155](https://github.com/interagent/committee/pull/155))

### Deprecated

- Deprecate use of `JsonSchema::Schema` object. ([#147](https://github.com/interagent/committee/pull/147))

## [2.2.1] - 2018-09-20

### Added

- Add numeric response status support for openapi 2. ([#141](https://github.com/interagent/committee/pull/141))

## [2.2.0] - 2018-09-06

### Added

- Add support for `multipart/form-data` when processing requests. ([#127](https://github.com/interagent/committee/pull/127))

## [2.1.1] - 2018-08-04

### Fixed

- Fix the `committee-stub` bin so that it runs if installed as a gem. ([#127](https://github.com/interagent/committee/pull/127))

## [2.1.0] - 2017-03-26

### Added

- Support validating header schemas in OpenAPI 2. ([#122](https://github.com/interagent/committee/pull/122))

## [2.0.1] - 2017-02-27

### Added

- Support either a string *or* an integer for status code responses. ([#125](https://github.com/interagent/committee/pull/125))

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
