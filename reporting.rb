require 'rubygems'
require 'sinatra'
require 'mongo'
require 'gruff'
require 'uri'
require './google_rank_checker'
require './bing_rank_checker'

TARGET = 'enrichnc.org'

get '/' do
  "Are you supposed to be here?"
end

get '/charts' do
  ret_string = '';
  get_keywords().each do | keyword |
    ret_string = ret_string + '<p><b>' + keyword + '</b><br /><img src = "/chart_image/' + keyword + '" /></p>'
  end
  ret_string
end

get '/chart_image/:keyword' do |keyword|
  content_type 'image/png'
  google_stats = Hash.new
  bing_stats = Hash.new
  coll = get_stats_collection
  coll.find( :keyword => keyword, :engine => "google" ).each {| row | google_stats[ row[ "date" ] ] = row[ "rank" ] }
  coll.find( :keyword => keyword, :engine => "bing" ).each {| row | bing_stats[ row[ "date" ] ] = row[ "rank" ] }
  bar_data = Array.new
  bar_data[0] = Array.new
  bar_data[1] = Array.new
  google_stats.each { |item| bar_data[0] << ( item[1]==-1 ? 0 : item[1] ).to_i }
  bing_stats.each { |item| bar_data[1] << ( item[1]==-1 ? 0 : item[1] ).to_i }
  labels = Array.new

  google_stats.each { |item| labels<< item[0]}
  g = Gruff::Line.new(400)
  g.title = keyword
  g.data( 'Google', bar_data[0], '#00933B' )    
  g.data( 'Bing', bar_data[1], '#FF8C00' )   
  g.to_blob
end

get '/update_ranks' do
  coll = get_stats_collection 
  google = GoogleRankChecker.new
  bing = BingRankChecker.new
  get_keywords().each do | keyword |
    rank = google.find_rank( keyword, TARGET );
    result = {"engine"=>"google", "date"=>Time.now.strftime("%m/%d/%Y"), "keyword"=>keyword, "rank"=>rank}
    coll.insert( result )
    rank = bing.find_rank( keyword, TARGET );
    result = {"engine"=>"bing", "date"=>Time.now.strftime("%m/%d/%Y"), "keyword"=>keyword, "rank"=>rank}
    coll.insert( result )
  end
  "done"
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
