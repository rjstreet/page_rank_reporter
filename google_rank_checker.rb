require 'rubygems'
require 'open-uri'
require 'hpricot'

class GoogleRankChecker
  def find_rank( search, search_for_domain )
    page_num = 0
    max_pages = 8
    count = 0
    search = URI.escape( search )
    while page_num < max_pages
      page_num += 1
      result_num = (page_num-1) * 10
      elements = Hpricot.parse( open("http://www.google.com/search?q=#{search}&start=#{result_num}&sa=N")).search("ol li.g h3.r a.l")
      elements.each do | el |
        host = URI.parse(el.attributes['href']).host rescue next 
        if( host != nil ) 
          count += 1
          if(host.include?(search_for_domain) or search_for_domain.include?(host))
            return count 
          end
        end
      end
    end
    #Couldn't find it
    return -1
  end
end
