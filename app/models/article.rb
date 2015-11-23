require "sinatra"
require "pg"
require "pry"
require "uri"

require_relative "../../db_module"

class Article
  include DatabaseModule

  attr_reader :title, :url, :description, :errors

  def initialize(arg_hash = { "title" => nil, "url" => nil, "description" => nil})
    @title = arg_hash["title"]
    @url = arg_hash["url"]
    @description = arg_hash["description"]
    @errors = []
  end

  def valid?
    missing_fields_error
    invalid_url_error_not_blank
    duplicate_url_error
    description_length_error_not_blank
    outcome = true if errors.empty?
    outcome ||= false
  end

  def save
    if valid?
      db_connection do |conn|
        sql_query = %(
        INSERT INTO articles (title, url, description)
        VALUES ($1, $2, $3)
        )
        data = [title, url, description]
        conn.exec_params(sql_query, data)
      end
      outcome = true
    end
    outcome ||= false
  end

  def self.all
    db_connection do |conn|
      @@articles = conn.exec("SELECT title, url, description FROM articles")
    end
    article_array = []
    @@articles.each do |article|
      article_array << Article.new({"title" => article["title"], "url" => article["url"], "description" => article["description"]})
    end
    article_array
  end

  private

  def valid_url?(url)
    valid_schemes = ["http://", "https://"]
    valid_schemes.any? { |scheme| scheme == url[0,7] || scheme == url[0,8] }
  end

  def missing_fields_error
    if title.empty? || url.empty? || description.empty?
      errors << "Please completely fill out form"
    end
  end

  def invalid_url_error_not_blank
    if !valid_url?(url) && !url.empty?
      errors << "Invalid URL"
    end
  end

  def duplicate_url_error
    if Article.all.any? { |article| article.url == url }
      errors << "Article with same url already submitted"
    end
  end

  def description_length_error_not_blank
    if description.length <= 20 && !description.empty?
      errors << "Description must be at least 20 characters long"
    end
  end
end
