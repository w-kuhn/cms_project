require 'sinatra'
require 'sinatra/reloader' if development?
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def find_file(name)
  @files.find { |file| File.basename(file) == name }
end

def load_file_content(document)
  case File.extname(document)
  when '.md'
    render_markdown(document)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    File.read(document)
  end
end

def render_markdown(markdown_file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(File.read(markdown_file))
end

before do
  @files = Dir.glob(Dir.pwd + '/data/*')
end

get '/' do
  @documents_list = @files.map { |doc| File.basename(doc) }
  erb :index, layout: :layout
end

get '/:file_name' do
  document = find_file(params[:file_name])

  if document
    load_file_content(document)
  else
    session[:message] = "\"#{params[:file_name]}\" does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  document = find_file(params[:file_name])

  if document
    @document = File.read(document)
    @document_name = params[:file_name]
  else
    session[:message] = "\"#{params[:file_name]}\" does not exist."
    redirect '/'
  end
  
  erb :edit_document, layout: :layout
end

post '/:file_name' do
  document = find_file(params[:file_name])

  File.write(document, params[:content].strip)
  session[:message] = "Changes have been saved."
  redirect "/"
end