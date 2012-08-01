$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'rdf'
require 'Work'
require 'Base'
require 'csv'

#Hpricot seg fault, can't see issue.
#seg fault, but empty file
BAD = ["data/cache/1/17544", "data/cache/1/10023"]
  
#others:
#No art work found - database error, 13781. Intermittent fault?
count = 0    
File.open("#{ARGV[1]}/gac.nt", "w") do |f|

  Dir.glob("#{ARGV[0]}/*/*") do |file|
    
    data = File.new(file)
    
    writer = RDF::NTriples::Writer.new( f )
    begin
     #puts file
     if !BAD.include?(file)
       work = Work.new( File.basename(file), data )
       statements = work.statements()
       statements.each do |stmt|
          writer << stmt
      end
      count = count + 1
     end
    rescue StandardError => e
      puts "Failed to convert #{file}"
      puts e
      puts e.backtrace
    end
    
  end
end

puts "Converted #{count} works to RDF"

CSV.open("#{ARGV[1]}/sitters.csv", "w") do |csv|
  Base.sitters.each do |k,v|
    csv << [k, v]
  end
end

CSV.open("#{ARGV[1]}/places.csv", "w") do |csv|
  Base.places.each do |k,v|
    csv << [k, v]
  end
end