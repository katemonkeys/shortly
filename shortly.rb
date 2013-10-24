require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'digest/sha1'
require 'pry'
require 'uri'
require 'open-uri'
require 'handlebars'
require 'bcrypt'
# require 'nokogiri'

###########################################################
# Configuration
###########################################################

set :public_folder, File.dirname(__FILE__) + '/public'

enable :sessions

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

# Handle potential connection pool timeout issues
after do
    ActiveRecord::Base.connection.close
end

# turn off root element rendering in JSON
ActiveRecord::Base.include_root_in_json = false

###########################################################
# Models
###########################################################
# Models to Access the database through ActiveRecord.
# Define associations here if need be
# http://guides.rubyonrails.org/association_basics.html

class Link < ActiveRecord::Base
    attr_accessible :url, :code, :visits, :title

    has_many :clicks

    validates :url, presence: true

    before_save do |record|
        record.code = Digest::SHA1.hexdigest(url)[0,5]
    end
end

class User < ActiveRecord::Base
  attr_accessible :username, :email, :password_hash, :password_salt

  validates :username, presence: true
end

class Click < ActiveRecord::Base
    belongs_to :link, counter_cache: :visits
end



#########
#https://gist.github.com/nopolabs/1458038
#########

helpers do
  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:username]
  end
end



###########################################################
# Routes
###########################################################


get '/links' do
    links = Link.order("created_at DESC")
    links.map { |link|
        link.as_json.merge(base_url: request.base_url)
    }.to_json
end

post '/links' do
    # binding.pry
    data = JSON.parse request.body.read
    uri = URI(data['url'])
    raise Sinatra::NotFound unless uri.absolute?
    link = Link.find_by_url(uri.to_s) ||
           Link.create( url: uri.to_s, title: get_url_title(uri) )
    link.as_json.merge(base_url: request.base_url).to_json
    console.log("request in POST: "+request.base_url);
end

get "/signup" do
  erb :signup
end

post "/signup" do
  data = JSON.parse request.body.read
  username = data['username']
  email = data['email']

  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

  #raise Sinatra::NotFound unless uri.absolute?

  console.log(data)
  user = Link.find_by_url(uri.to_s) ||
           Link.create( url: uri.to_s, title: get_url_title(uri) )
    link.as_json.merge(base_url: request.base_url).to_json

  #ideally this would be saved into a database, hash used just for sample
  :users [params[:username]] = {
    :salt => password_salt,
    :passwordhash => password_hash
  }

  session[:username] = params[:username]
  redirect "/"
end

post "/login" do
  if userTable.has_key?(params[:username])
    user = userTable[params[:username]]
    if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
      session[:username] = params[:username]
      redirect "/"
    end
  end
  erb :error
end
 
get "/logout" do
  session[:username] = nil
  redirect "/"
end

get '/login' do
    erb :login
end

get '/' do       #needs to be here?
    erb :index
end



# get '/stats' do
#     time = Click.order("updated_at DESC")
#     time.map { |time|
#         time.as_json.merge(updated_at: request.updated_at)
#     }.to_json
# The data that I have is the updated_at times
#for all links in my activerecord database. Let's
#first display all those and then sort, then bin.
# end

get '/:url' do
    link = Link.find_by_code params[:url]
    raise Sinatra::NotFound if link.nil?
    link.clicks.create!
    redirect link.url
end

###########################################################
# Utility
###########################################################

def read_url_head url
    head = ""
    url.open do |u|
        begin
            line = u.gets
            next  if line.nil?
            head += line
            break if line =~ /<\/head>/
        end until u.eof?
    end
    head + "</html>"
end

def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    result = read_url_head(url).match(/<title>(.*)<\/title>/)
    result.nil? ? "" : result[1]
end
