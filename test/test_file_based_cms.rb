ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../file_based_cms"

class File_Based_CMS_Test < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    body = last_response.body
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_match /about\.md/, body
    assert_match /history\.txt/, body
    assert_match /changes\.txt/, body
  end

  def test_text_document_contents
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_match /only waiting to die/, last_response.body
  end

  def test_markdown_document_contents
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<strong>on risk</strong>"
  end

  def test_file_not_found
    get "/fake_file.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "fake_file\.txt"

    get "/"
    assert_silent { last_response.body }
  end
end