require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uri'
require 'set'

def make_directories()
  (0..9).each do |dir|
    begin
      Dir.mkdir( File.join(ARGV[0], "#{dir}") )
    rescue => e
      $stderr.puts e
    end
  end
end

make_directories()

$stderr.puts "Caching all works"

count = 0
File.open("#{ARGV[0]}/works.txt", "r").each do |line|
  id = line.match(/obj=([0-9A-Za-z]+)/)[1]
  cache_file = File.join(ARGV[0], id[0..0], id)
  #only crawl if file doesn't exist
  if !File.exists?( cache_file  )
    uri = URI.parse( line )
    count = count + 1 
    begin
      sleep(1.0)
      page_data = uri.read
      f = File.open( cache_file , "w" )
      f.puts(page_data)
      if (count % 100) == 0
        $stderr.puts "Cached #{count} works"
      end    
    rescue => e
      $stderr.puts e
      $stderr.puts "Unable to fetch #{work}"
    end   
  end
end  
