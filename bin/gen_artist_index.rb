require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uri'
require 'set'

BROWSE_INDEX_BASE="http://www.gac.culture.gov.uk/artists_list.aspx?&l=A&lt=thumbnails&sb=ArtistName&sl="

def fetch_page(url)
  sleep(0.5)
  page = Hpricot( open(url) )
  return page  
end

def fetch_letter_ranges( letter )
  page = fetch_page("http://www.gac.culture.gov.uk/artists_list.aspx?l=#{letter}")
  results = {}
  current = nil
  page.search("#makerRanges option").each do |option|
    if current == nil
      current = option.inner_text
    end
    results[ option.inner_text ] = 0 
  end
  paginator = page.search(".paginatorLast")
  pages = 1
  if paginator[0] != nil
    pages = paginator.attr("href").match(/\&pg=([0-9]+)/)[1].to_i
  end   
  results[ current ] = pages
  results.keys.each do |key|
    if results[key] == 0
      page = fetch_page( "http://www.gac.culture.gov.uk/artists_list.aspx?l=#{letter}&lt=thumbnails&sb=ArtistName&sl=#{URI.encode(key)}" )
      pages = page.search(".paginatorLast").attr("href").match(/\&pg=([0-9]+)/)[1].to_i
      results[key] = pages
    end 
  end    
  return results
end

#Config is:
# { "A" => { "Aa-Ab" => 5 .. } } 
def fetch_artists(config)
  
  artists = []
        
  return artists
  
end

$stderr.puts "Finding all artist page sections"
config = {}
('A'..'Z').each do |letter|
  config[letter] = fetch_letter_ranges( letter ) unless letter == "X"
end

puts "Generating artist index"

File.open("#{ARGV[0]}/artists.txt", "w") do |f| 
  config.keys.each do |letter|  
    pages = config[letter]
    $stderr.puts "Crawling #{letter}"
    pages.keys.each do |section|    
      page_count = pages[section]
      page_count.times do |page|
        $stderr.puts "Fetching #{letter}, #{section}, #{page+1}"      
        page = fetch_page("http://www.gac.culture.gov.uk/artists_list.aspx?l=#{letter}&lt=thumbnails&sb=ArtistName&sl=#{URI.encode(section)}&pg=#{page+1}")
        links = page.search(".eliteSearchDrop p a")
        links.each do |link|
          f.puts "http://www.gac.culture.gov.uk#{link["href"]}"
        end
      end    
    end  
  end 
end