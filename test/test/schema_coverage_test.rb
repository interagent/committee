# frozen_string_literal: true

require "test_helper"

describe Committee::Test::SchemaCoverage do
  before do
    @schema_coverage = Committee::Test::SchemaCoverage.new(open_api_3_coverage_schema)
  end

  describe '.merge_report' do
    it 'can merge 2 coverage reports together' do
      report = Committee::Test::SchemaCoverage.merge_report(
        {
          '/posts' => {
            'get' => {
              'responses' => {
                '200' => true,
                '404' => false,
              },
            },
            'post' => {
              'responses' => {
                '200' => false,
              },
            },
          },
          '/likes' => {
            'post' => {
              'responses' => {
                '200' => true,
              },
            },
          },
        },
        {
          '/posts' => {
            'get' => {
              'responses' => {
                '200' => true,
                '404' => true,
              },
            },
            'post' => {
              'responses' => {
                '200' => false,
              },
            },
          },
          '/likes' => {
            'post' => {
              'responses' => {
                '200' => false,
                '400' => false,
              },
            },
          },
          '/users' => {
            'get' => {
              'responses' => {
                '200' => true,
              },
            },
          },
        },
      )

      assert_equal({
        '/posts' => {
          'get' => {
            'responses' => {
              '200' => true,
              '404' => true,
            },
          },
          'post' => {
            'responses' => {
              '200' => false,
            },
          },
        },
        '/likes' => {
          'post' => {
            'responses' => {
              '200' => true,
              '400' => false,
            },
          },
        },
        '/users' => {
          'get' => {
            'responses' => {
              '200' => true,
            },
          },
        },
      }, report)
    end
  end
end
