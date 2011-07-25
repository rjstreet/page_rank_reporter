require 'rubygems'
require 'sinatra'
require 'mongo'
require 'uri'
require 'gruff'
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
    google_stats.each { |item| bar_data[0] << ( item[1]==-1 ? 0 : item[1] ).to_i }
    bing_stats.each { |item| bar_data[1] << ( item[1]==-1 ? 0 : item[1] ).to_i }
    labels = Array.new


    g = Gruff::Line.new
    g.title = keyword
    g.data( "Google", bar_data[0] )
    g.data( "Bing", bar_data[1] )
    g.write( keyword + ".png" )
    ret_string = '<p><b>' + keyword + '</b><br /><img src="' + keyword + '.png" /></p>'
    #google_stats.each { |item| labels<< item[0]}
    #ret_string = ret_string + '<p><b>' + keyword + '</br><img src="' + Gchart.line(:data => bar_data[0], :axis_with_labels => "y", :bar_colors => 'FF1111', :legend => ['Google'], :custom => 'chg=10,15,1,0' ) + '" title="bar" alt="bar"><img src="' + Gchart.line(:data => bar_data[1], :axis_with_labels => "y", :bar_colors => '1111FF', :legend => ['Bing'], :custom => 'chg=10,15,1,0' ) + '" title="bar" alt="bar"></p>'
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
