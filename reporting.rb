require 'rubygems'
require 'sinatra'
require 'googlecharts'
require 'mongo'
require 'uri'

get '/' do
  "Are you supposed to be here?"
end

get '/update_ranks' do
  coll = get_stats_collection 
  google = GoogleRankChecker.new
  bing = BingRankChecker.new
end

get '/keywords' do
  keywords = get_keywords()
  keywords.each {|word| puts word }
end

def get_keywords
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  coll = db.collection( "keywords" )
  keywords = Array.new
  coll.find().each {|row| keywords.add row[keyword]}
  keywords
end

def get_stats_collection
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  coll = db.collection( "stats" )
  coll
end
