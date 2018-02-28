require 'sinatra'
require 'sinatra/reloader' if development?
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def find_file(name)
  @files.find { |file| File.basename(file) == name }
end

def data_path
  if ENV["RACK_ENV"] == "test"
    Dir.pwd + '/test/data/'
  else
    Dir.pwd + '/data/'
  end
end

def load_user_credentials
  credentials_file_path =
    if ENV["RACK_ENV"] == "test"
      Dir.pwd + '/test/users.yml'
    else
      Dir.pwd + '/users.yml'
    end
  YAML.load_file(credentials_file_path)
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

def require_valid_credentials
  unless session[:username]
    session[:error] = "You must be signed in to do that."
    redirect '/'
  end
end

def require_admin_credentials
  unless session[:username] == "admin"
    session[:error] = "You must be signed in as admin to do that."
    redirect '/'
  end
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    encrypted_password = BCrypt::Password.new(credentials[username])
    encrypted_password == password
  else
    false
  end
end

before do
  @files = Dir.glob(data_path + '*')
end

get '/' do
  @documents_list = @files.map { |doc| File.basename(doc) }
  erb :index, layout: :layout
end

get '/users/signin' do
  erb :sign_in, layout: :layout
end

get '/new' do
  require_valid_credentials

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
  require_valid_credentials

  document = find_file(params[:file_name])
  
  @document = File.read(document)
  
  erb :edit_document, layout: :layout
end

post '/create' do
  require_valid_credentials

  unless valid_file_name?(params[:document_name])
    session[:error] = "File name must be at least one character and have an extension of '.txt' or '.md'."
    status 422
    erb :new_document, layout: :layout
  else
    document_name = params[:document_name].strip
    File.write(data_path + document_name, "")
    session[:success] = "#{document_name} created successfully."
    redirect '/'
  end
end

post '/:file_name' do
  require_valid_credentials

  document = find_file(params[:file_name])

  File.write(document, params[:content])

  session[:success] = "#{params[:file_name]} has been updated."
  redirect "/"
end

post '/:file_name/delete' do
  require_valid_credentials

  FileUtils.rm(find_file(params[:file_name]))
  session[:success] = "#{params[:file_name]} has been deleted."
  redirect '/'
end

post '/users/signin' do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:success] = 'Welcome!'
    redirect '/'
  else
    session[:error] = "Invalid Credentials"
    status 422
    erb :sign_in
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:success] = "You have been signed out."
  redirect '/'
end