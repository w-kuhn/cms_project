require 'sinatra'
require 'sinatra/reloader' if development?

configure do
  # sessions
end

configure do
  set :erb, :escape_html => true
end

before do
  @files = Dir.glob(Dir.pwd + '/data/*')
end

get '/' do
  @documents_list = @files.map { |doc| File.basename(doc) }

  erb :index, layout: :layout
end

def find_file(name)
  @files.find { |file| file =~ Regexp.new(name) }
end

get '/:file_name' do
  @document = find_file(params[:file_name])
  headers['Content-Type'] = 'text/plain'
  File.read(@document)
end
