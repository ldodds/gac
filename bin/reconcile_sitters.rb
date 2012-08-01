require 'rubygems'
require 'kasabi'
require 'csv'

#reconcile using the provided client
def reconcile(uri, label, client, type, f)
  query = Kasabi::Reconcile::Client.make_query("#{label}", 3, :any, type, nil)
    
  begin    
    results = client.reconcile(query)
    if results != nil && results.length > 0 && results[0]["match"] == true
      f.puts "<#{uri}> <http://www.w3.org/2002/07/owl#sameAs> <#{results[0]["id"]}>."
    else
      f.puts "# No match for #{uri}"
    end  
  rescue HTTPClient::ReceiveTimeoutError => e  
     $stderr.puts "# Timeout for #{uri}"      
  rescue => x
     $stderr.puts x
     $stderr.puts x.backtrace 
  end 
  
end

reconciler = Kasabi::Reconcile::Client.new(
  "http://api.kasabi.com/dataset/dbpedia-36/apis/reconciliation", :apikey => ENV["KASABI_API_KEY"])

File.open("#{ARGV[1]}/sitter-links.nt", "w") do |f|
  CSV.open("#{ARGV[0]}/sitters.csv", "r").each do |line|
    uri, label = line[0], line[1]  
    reconcile(uri, label, reconciler, "http://dbpedia.org/ontology/Person", f)
  end
end  