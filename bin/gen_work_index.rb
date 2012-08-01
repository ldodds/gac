require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uri'
require 'set'

def fetch_page(url)
  sleep(0.5)
  page = Hpricot( open(url) )
  return page  
end

$stderr.puts "Generating art work index"

count = 0
File.open("#{ARGV[0]}/works.txt", "w") do |f|
  File.open("#{ARGV[0]}/artists.txt", "r").each do |artist|
    artist = artist.chomp     
    page = fetch_page( artist )
    #find links on this page
    page.search("#filterResults .imageCell a").each do |link|
      f.puts "http://www.gac.culture.gov.uk#{link["href"]}"
    end
    #if we have >1 page, then fetch those too
    paginator = page.at(".paginatorLast")
    if paginator 
      pages = paginator["href"].match(/\&pg=([0-9]+)/)[1].to_i
      pages = pages - 1
      pages.times do |number|        
        other = fetch_page( "#{artist}&pg=#{number+2}&vw=th&sb=WorkDate" )
        other.search("#filterResults .imageCell a").each do |otherlink|
          f.puts "http://www.gac.culture.gov.uk#{otherlink["href"]}"
        end                
      end      
    end    
    count = count + 1
    if (count % 10) == 0
      $stderr.puts "Processed #{count} artists"
    end             
  end   
end
puts "Processed #{count} artists"