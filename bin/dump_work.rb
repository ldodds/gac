$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'
require 'linkeddata'
require 'Work'

data = File.new(ARGV[0])

work = Work.new( File.basename(ARGV[0]), data )

if ARGV[1] == nil || ARGV[2] == "fields"
  puts work.fields.pretty_inspect
else  
  statements = work.statements()
  buffer = RDF::Writer.for(:rdfxml).buffer do |writer|
    statements.each do |stmt|
       writer << stmt
    end
  end    
  puts buffer
end
