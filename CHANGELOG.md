## Unreleased

## 0.11.2 (2020-05-23)
* Allow date and time content in YAML #81

## 0.11.1 (2020-05-09)
* fix too many warning

## 0.11.0 (2020-05-09)
* Add committee friendly interface to use remote references. #74
* Prevent SystemStackError on recursive schema reference #76
* support newest ruby versions #78

## 0.10.0 (2020-04-01)
* Support $ref to objects in other OpenAPI yaml files #66
* Allow $ref for path item objects #71

## 0.9.0 (2020-03-22)
* Added support for validating UUID formatted strings #67

## 0.8.0 (2020-01-21)
* Append the example to the Pattern validator error message #64

## 0.7.0 (2020-01-15)
* Avoid potential `.send(:exit)` #58
* Improve PathItemFinder #44

## 0.6.1 (2019-10-12)
* Bugfix: validate non-nullable response header #54
* Improve grammar in error messages #55
* fix object validator in case of properties missing #56

## 0.6.0 (2019-10-05)
* add email format validation on string #51

## 0.5.0 (2019-09-28)
* Add max and min length validators for string. #45
* Support for minItems and maxItems in array #49

## 0.4.1 (2019-07-27)
* release missed

## 0.4.0 (2019-07-27)
* Add minimum and maximum checks for `integer` and `number` data types (#43)

## 0.3.1 (2019-06-04)
* Add additionalProperties default value (#40)

## 0.3.0 (2019-06-01)

### features
* Perform a strict check on object properties (#33)

### Bugfix
* Support discriminator without mapping (#35)
* Fix upper case request param validation (#38)

## 0.2.7 (2019-05-20)
* Fix for release miss

## 0.2.6 (2019-05-20)
* Add support for discriminator (#32)

## 0.2.5 (2019-04-12)
* Support one of validator (#26)

## 0.2.3 (2019-03-18)
* validate_header_parameter support case incentive (#25)

## 0.2.2 (2019-01-06)
* bugfix for datetime validate (#20)

## 0.2.1 (2019-01-03)
* raise error when invalid datetime format (#19)

## 0.2.0 (2019-01-02)
* support header validate (#18)

## 0.1.9 (2019-01-01)
* add strict option (#17)

## 0.1.8 (2018-12-31)
* add select_media_type method(#16)

## 0.1.7 (2018-12-30)
* Float value validate bugfix (#15)

## 0.1.6 (2018-12-29)
* Support allOf definition (#11)
* Support wildcard status code (#12)
* Support wildcard content type (#13)

## 0.1.5 (2018-12-23)
* First release for production usage
