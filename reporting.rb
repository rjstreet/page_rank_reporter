require 'rubygems'
require 'sinatra'
require 'googlecharts'
require 'mongo'
require 'uri'
require './google_rank_checker'
require './bing_rank_checker'

TARGET = 'enrichnc.org'

get '/' do
  "Are you supposed to be here?"
end

get '/update_ranks' do
  coll = get_stats_collection 
  google = GoogleRankChecker.new
  bing = BingRankChecker.new
  get_keywords().each do | keyword |
puts keyword
    rank = google.find_rank( keyword, TARGET );
    result = {"engine"=>"google", "date"=>Time.nowstrftime("%m/%d/%Y"), "keyword"=>keyword, "rank"=>rank}
    coll.insert( result )
    rank = bing.find_rank( keyword, TARGET );
    results = {"engine"=>"bing", "date"=>Time.nowstrftime("%m/%d/%Y"), "keyword"=>keyword, "rank"=>rank}
    coll.insert( result )
  end
end

get '/keywords' do
  keywords = get_keywords()
  output = '<ul>'
  keywords.each {|word| output = output + '<li>' + word }
  output = output + '</ul>'
end

def get_keywords
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  coll = db.collection( "keywords" )
  keywords = Array.new
  coll.distinct('keyword').each {|row| keywords << row}
  keywords
end

def get_stats_collection
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  coll = db.collection( "stats" )
  coll
end
