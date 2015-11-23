require "sinatra"
require "pg"
require "pry"
require_relative "./app/models/article"
require_relative "db_module"

set :views, File.join(File.dirname(__FILE__), "app/views")

use Rack::Session::Cookie, {
  secret: "keep_it_secret_keep_it_safe"
}

include DatabaseModule

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

get '/articles' do
  @all_articles = Article.all
  erb :index
end

get '/articles/new' do
  clear_session_vars
  erb :articles_new
end

post '/articles/new' do
  article = Article.new( {"title" => params[:title], "url" => params[:url], "description" => params[:description]} )
  article.valid?
  if article.errors.any?
    assign_session_vars( {title: params[:title], url: params[:url], description: params[:description]} )
    @errors = article.errors
    # binding.pry
    erb :articles_new
  else
    article.save
    clear_session_vars
    redirect '/articles'
  end

end

def assign_session_vars(arg_hash)
  session[:prev_title] = arg_hash[:title]
  session[:prev_url] = arg_hash[:url]
  session[:prev_description] = arg_hash[:description]
end

def clear_session_vars
 session[:prev_title] = nil
 session[:prev_url] = nil
 session[:prev_description] = nil
end
