require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rdf'

SCHEME = RDF::URI.new("http://data.kasabi.com/dataset/government-art-collection/subjects")

def uri(path)
  return RDF::URI.new( "http://data.kasabi.com/dataset/government-art-collection#{path}" )
end

def expand(writer, id, parent, find_children=false)
  url = "http://www.gac.culture.gov.uk/subjects_expand.aspx?Termid=#{id}"
  page = Hpricot( open( url ) )
  
  page.search("a").each do |link|
    subject_uri = uri( "/subjects/#{link.parent["id"]}" )
    label = link.inner_text
    if label.match(/(.+) \[[0-9]+\]$/)
      label = label.match(/(.+) \[[0-9]+\]$/)[1]
    end
    
    writer << RDF::Statement.new( subject_uri, RDF.type, RDF::SKOS.Concept )
    writer << RDF::Statement.new( subject_uri, RDF::RDFS.label, label )
    writer << RDF::Statement.new( subject_uri, RDF::SKOS.prefLabel, label ) 
    writer << RDF::Statement.new( subject_uri, RDF::SKOS.inScheme, SCHEME )
    writer << RDF::Statement.new( subject_uri, RDF::SKOS.broader, parent )
    writer << RDF::Statement.new( parent, RDF::SKOS.narrower, subject_uri )    
    expand( writer, link.parent["id"], subject_uri) if find_children    
  end  
  
end

File.open("#{ARGV[0]}/subjects.nt", "w") do |f|
  writer = RDF::NTriples::Writer.new( f )
  
  page = Hpricot( open("http://www.gac.culture.gov.uk/subjects_browser.aspx") )
  subjects = page.search("#navSubjectBrowser a")
  subjects.each do |link|
    subject_uri = uri( "/subjects/#{link.parent["id"]}" )
    label = link.inner_text
    writer << RDF::Statement.new( subject_uri, RDF.type, RDF::SKOS.Concept )
    writer << RDF::Statement.new( subject_uri, RDF::RDFS.label, label )
    writer << RDF::Statement.new( subject_uri, RDF::SKOS.prefLabel, label ) 
    writer << RDF::Statement.new( subject_uri, RDF::SKOS.inScheme, SCHEME )
    writer << RDF::Statement.new( SCHEME, RDF::SKOS.hasTopConcept, subject_uri)    
    
    expand( writer, link.parent["id"], subject_uri, true)
    
  end
  
  
end
