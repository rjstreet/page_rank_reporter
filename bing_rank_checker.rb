require 'rubygems'
require 'open-uri'
require 'hpricot'

class BingRankChecker
  def find_rank( search, search_for_domain )
    page_num = 0
    max_pages = 8
    count = 0
    search = URI.escape( search )
    while page_num < max_pages
      page_num += 1
      result_num = (page_num-1) * 10
      elements = Hpricot.parse( open("http://www.bing.com/search?q=#{search}&go=&qs=n&sk=&first=#{result_num}&FORM=PERE")).search("ul.sb_results li h3 a")
      elements.each do | el |
        host = URI.parse(el.attributes['href']).host rescue next 
puts host
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


