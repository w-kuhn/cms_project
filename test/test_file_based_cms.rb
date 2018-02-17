ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../file_based_cms.rb"

class File_Based_CMS_Test < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    index_response =
      <<~HTML
        <!doctype html>
        <html lang="en-US">
          <head>
            <title>This is the Title</title>
          </head>
          <body>
            <main>
              <main>
          <div>
            <ul>
                <li><a href="/about.txt">about.txt</a></li>
                <li><a href="/history.txt">history.txt</a></li>
                <li><a href="/changes.txt">changes.txt</a></li>
            </ul>
          </div>
        </main>
            </main>
          </body>
        </html>
      HTML

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal index_response, last_response.body
  end
end