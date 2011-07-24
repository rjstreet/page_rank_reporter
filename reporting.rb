require 'rubygems'
require 'sinatra'
require 'googlecharts'
require 'mongo'
require 'uri'
require 'gchart'
require './google_rank_checker'
require './bing_rank_checker'

TARGET = 'enrichnc.org'

get '/' do
  "Are you supposed to be here?"
end

get '/charts' do
  ret_string = '';
  get_keywords().each do | keyword |
    google_stats = Hash.new
    bing_stats = Hash.new
    coll = get_stats_collection
    coll.find( :keyword => keyword, :engine => "google" ).each {| row | google_stats[ row[ "date" ] ] = row[ "rank" ] }
    coll.find( :keyword => keyword, :engine => "bing" ).each {| row | bing_stats[ row[ "date" ] ] = row[ "rank" ] }
    bar_data = Array.new
    bar_data[0] = Array.new
    bar_data[1] = Array.new
    google_stats.each { |item| bar_data[0] << ( item[1]==-1 ? 0 : item[1] ) }
    bing_stats.each { |item| bar_data[1] << ( item[1]==-1 ? 0 : item[1] ) }
    labels = Array.new
    google_stats.each { |item| labels<< item[0]}
    ret_string = ret_string + '<p><b>' + keyword + '</br><img src="' + Gchart.line(:size => '200x300', :data => bar_data, :axis_with_labels => ['x', 'y'], :axis_labels => [labels, '0|10|20|30|40|50|60|70|80|90|100'], :bar_colors => 'FF1111,1111FF', :stacked=>false, :legend => ['Google', 'Bing'] ) + '" title="bar" alt="bar"></p>'
  end
  ret_string
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
