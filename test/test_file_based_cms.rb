ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../file_based_cms"

class File_Based_CMS_Test < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(root_path)
  end

  def teardown
    FileUtils.rm_rf(root_path)
  end

  def create_document(name, content = "")
    File.open(root_path + name, "w") do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document("about.md")
    create_document("history.txt")
    create_document("changes.txt")

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_match /about\.md/, last_response.body
    assert_match /history\.txt/, last_response.body
    assert_match /changes\.txt/, last_response.body
  end

  def test_text_document_contents
    create_document("history.txt", "And the day came when the risk")
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_match /the day came when/, last_response.body
  end

  def test_markdown_document_contents
    create_document("about.md", "**on risk**")
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "&lt;strong&gt;on risk&lt;/strong&gt"
  end

  def test_file_not_found
    get "/fake_file.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "fake_file\.txt"

    get "/"
    assert_silent { last_response.body }
  end

  def test_edit_links_appear
    create_document("about.md")
    get '/'
    assert_includes last_response.body, "edit"
  end

  def test_edit_form_renders
    create_document("about.md")
    get '/about.md/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Edit the contents of the document:"
    assert_includes last_response.body, "&lt;textarea name=&quot;content&quot;"
  end

  def test_update_document
    create_document("changes.txt")
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated."

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_new_document_link_appears
    get '/'
    
    assert_includes last_response.body, "New Document"
  end

  def test_new_document_form_renders
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "&lt;form action=&quot;/create&quot; method=&quot;post&quot;&gt;"
  end

  def test_new_empty_document_created
    post "/create", document_name: "new.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "new.txt created successfully."

    get "/new.txt"
    assert_equal 200, last_response.status
    assert last_response.body.empty?
  end

  def test_invalid_document_name
    ['.txt', '.md', ' .txt', '.', '', ' ', 'one.sav'].each do |bad_name|
      post "/create", document_name: bad_name
      assert_equal 422, last_response.status
      assert_includes last_response.body, "File name must be at least one character and have an extension of '.txt' or '.md'."
    end
  end

  def test_valid_document_name
    ['a.txt', 'b.md', 'a.txt', 'b.md'].each do |good_name|
      post "/create", document_name: good_name
      assert_equal 302, last_response.status
    end
  end

  def test_delete_button_appears
    create_document("changes.txt")
    get '/'
    assert_includes last_response.body, "&lt;button type=&quot;submit&quot;&gt;delete&lt;/button&gt;"
  end

  def test_document_deleted
    create_document("changes.txt")
    post "/changes.txt/delete"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been deleted."

    get "/"
    refute_includes last_response.body, "changes.txt"
  end
end
