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

dbpedia_reconciler = Kasabi::Reconcile::Client.new(
  "http://api.kasabi.com/dataset/dbpedia-36/apis/reconciliation", :apikey => ENV["KASABI_API_KEY"])

geonames_reconciler = Kasabi::Reconcile::Client.new(
  "http://api.kasabi.com/dataset/geonames/apis/reconciliation", :apikey => ENV["KASABI_API_KEY"])

os_reconciler = Kasabi::Reconcile::Client.new(
  "http://api.kasabi.com/dataset/ordnance-survey-linked-data/apis/reconciliation", :apikey => ENV["KASABI_API_KEY"])

yahoo_reconciler = Kasabi::Reconcile::Client.new(
  "http://api.kasabi.com/dataset/yahoo-geoplanet/apis/reconciliation", :apikey => ENV["KASABI_API_KEY"])
                
File.open("#{ARGV[1]}/place-links.nt", "w") do |f|
  CSV.open("#{ARGV[0]}/places.csv", "r").each do |line|
    uri, label = line[0], line[1]  
    reconcile(uri, label, dbpedia_reconciler, "http://dbpedia.org/ontology/Place", f)
    reconcile(uri, label, geonames_reconciler, "http://www.geonames.org/ontology#Feature", f)
    reconcile(uri, label, os_reconciler, nil, f)
    reconcile(uri, label, yahoo_reconciler, nil, f)
  end
end  