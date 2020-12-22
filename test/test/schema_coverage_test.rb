# frozen_string_literal: true

require "test_helper"

describe Committee::Test::SchemaCoverage do
  before do
    @schema_coverage = Committee::Test::SchemaCoverage.new(open_api_3_coverage_schema)
  end

  describe 'recording coverage' do
    def response_as_str(response)
      [:path, :method, :status].map { |key| response[key] }.join(' ')
    end

    def uncovered_responses
      @schema_coverage.report_flatten[:responses].select { |r| !r[:is_covered] }.map { |r| response_as_str(r) }
    end

    def covered_responses
      @schema_coverage.report_flatten[:responses].select { |r| r[:is_covered] }.map { |r| response_as_str(r) }
    end
    it 'can record and report coverage properly' do
      @schema_coverage.update_response_coverage!('/posts', 'get', '200')
      assert_equal([
        '/posts get 200',
      ], covered_responses)
      assert_equal([
        '/threads/{id} get 200',
        '/posts get 404',
        '/posts get default',
        '/posts post 200',
        '/likes post 200',
        '/likes delete 200',
      ], uncovered_responses)

      @schema_coverage.update_response_coverage!('/likes', 'post', '200')
      assert_equal([
        '/posts get 200',
        '/likes post 200',
      ], covered_responses)
      assert_equal([
        '/threads/{id} get 200',
        '/posts get 404',
        '/posts get default',
        '/posts post 200',
        '/likes delete 200',
      ], uncovered_responses)

      @schema_coverage.update_response_coverage!('/likes', 'delete', '200')
      assert_equal([
        '/posts get 200',
        '/likes post 200',
        '/likes delete 200',
      ], covered_responses)
      assert_equal([
        '/threads/{id} get 200',
        '/posts get 404',
        '/posts get default',
        '/posts post 200',
      ], uncovered_responses)

      @schema_coverage.update_response_coverage!('/posts', 'get', '422')
      assert_equal([
        '/posts get 200',
        '/posts get default',
        '/likes post 200',
        '/likes delete 200',
      ], covered_responses)
      assert_equal([
        '/threads/{id} get 200',
        '/posts get 404',
        '/posts post 200',
      ], uncovered_responses)

      assert_equal({
        '/threads/{id}' => {
          'get' => {
            'responses' => {
              '200' => false,
            },
          },
        },
        '/posts' => {
          'get' => {
            'responses' => {
              '200' => true,
              '404' => false,
              'default' => true,
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
          'delete' => {
            'responses' => {
              '200' => true,
            },
          },
        },
      }, @schema_coverage.report)

      @schema_coverage.update_response_coverage!('/posts', 'post', '200')
      @schema_coverage.update_response_coverage!('/posts', 'get', '404')
      @schema_coverage.update_response_coverage!('/threads/{id}', 'get', '200')
      assert_equal([
        '/threads/{id} get 200',
        '/posts get 200',
        '/posts get 404',
        '/posts get default',
        '/posts post 200',
        '/likes post 200',
        '/likes delete 200',
      ], covered_responses)
      assert_equal([], uncovered_responses)
    end
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
