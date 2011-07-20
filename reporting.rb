require 'rubygems'
require 'sinatra'
require 'googlecharts'
require 'mongo'

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
  db = Mongo::Connection.new.db("app624994")
  auth = db.authenticate( 'reporter', 'report12max' )
  coll = db.collection( "keywords" )
  keywords = Array.new
  coll.find().each {|row| array.add row[keyword]}
  keywords
end

def get_stats_collection
  db = Mongo::Connection.new.db("app624994")
  auth = db.authenticate( 'reporter', 'report12max' )
  coll = db.collection( "stats" )
  coll
end
