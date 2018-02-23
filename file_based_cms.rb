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

def root_path
  if ENV["RACK_ENV"] == "test"
    Dir.pwd + '/test/data/'
  else
    Dir.pwd + '/data/'
  end
end

def load_file_content(document)
  case File.extname(document)
  when '.md'
    erb render_markdown(document)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    File.read(document)
  end
end

def render_markdown(markdown_file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(File.read(markdown_file))
end

def valid_file_name?(file_name)
  base_name, extension = 
    File.basename(file_name, '.*'), File.extname(file_name)

  base_name =~ /\S+/ && ['.txt', '.md'].include?(extension)
end

before do
  @files = Dir.glob(root_path + '*')
end

get '/' do
  @documents_list = @files.map { |doc| File.basename(doc) }
  erb :index, layout: :layout
end

get '/new' do
  erb :new_document, layout: :layout
end

get '/:file_name' do
  document = find_file(params[:file_name])

  if document
    load_file_content(document)
  else
    session[:error] = "\"#{params[:file_name]}\" does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  document = find_file(params[:file_name])

  @document = File.read(document)
  
  erb :edit_document, layout: :layout
end

post '/create' do
  unless valid_file_name?(params[:document_name])
    session[:error] = "File name must be at least one character and have an extension of '.txt' or '.md'."
    status 422
    erb :new_document, layout: :layout
  else
    File.write(root_path + params[:document_name], "")
    session[:success] = "#{params[:document_name]} created successfully."
    redirect '/'
  end
end

post '/:file_name' do
  document = find_file(params[:file_name])

  File.write(document, params[:content])

  session[:success] = "#{params[:file_name]} has been updated."
  redirect "/"
end

post '/:file_name/delete' do
  FileUtils.rm(find_file(params[:file_name]))
  session[:success] = "#{params[:file_name]} has been deleted."
  redirect '/'
end