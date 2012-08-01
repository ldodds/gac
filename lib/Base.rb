require 'rubygems'
require 'rdf'

class Base

  attr_reader :statements
  
  SCHEMA = "http://data.kasabi.com/dataset/government-art-collection/schema"
  CONCEPT_SCHEME = RDF::URI.new( "http://data.kasabi.com/dataset/government-art-collection/subjects" )
  
  GAC = RDF::Vocabulary.new("#{SCHEMA}/")
  MEASURE = RDF::Vocabulary.new("http://buzzword.org.uk/rdf/measure#")
  
  @@DECLARED = []
  @@PLACES = {}
  @@SITTERS = {}

  def Base.sitters()
    return @@SITTERS 
  end

  def Base.places()
    return @@PLACES 
  end
              
  def initialize()
    @statements = []
  end  
  
  def property_name(field)
    return field.downcase.sub(" ", "-")
  end
  
  def declare_property(field)
    if !@@DECLARED.include?(field)
      name = property_name(field)
      @statements << RDF::Statement.new( GAC[name], RDF.type, RDF.Property )
      @statements << RDF::Statement.new( GAC[name], RDF::RDFS.label, field )
      @statements << RDF::Statement.new( GAC[name], RDF::RDFS.isDefinedBy, RDF::URI.new(SCHEMA) )
      @statements << RDF::Statement.new( RDF::URI.new(SCHEMA), RDF::RDFS.seeAlso, GAC[name] ) 
      @@DECLARED << field  
    end    
  end
    
  def declare_type(field)
      name = field
      @statements << RDF::Statement.new( GAC[name], RDF.type, RDF::RDFS.Class )
      @statements << RDF::Statement.new( GAC[name], RDF.type, RDF::OWL.Class )
      @statements << RDF::Statement.new( GAC[name], RDF::RDFS.label, field )
      @statements << RDF::Statement.new( GAC[name], RDF::RDFS.isDefinedBy, RDF::URI.new(SCHEMA) )
      @statements << RDF::Statement.new( RDF::URI.new(SCHEMA), RDF::RDFS.seeAlso, GAC[name] ) 
  end
  
  def link_id(elem, link_param)
    match = elem["href"].match(/#{link_param}=([0-9]+)/)
    if match
      return match[1]
    end
    return nil
  end
  
  def add_property(predicate, object)
    add_statement( @uri, predicate, object ) if (object != nil && object != "")
  end
   
  def add_statement(subject, predicate, object)
    @statements << RDF::Statement.new( subject, predicate, object )
  end
  
  def uri(path)
    if path.start_with?("http")
      return RDF::URI.new( path )
    end  
    return RDF::URI.new( "http://data.kasabi.com/dataset/government-art-collection#{path}" )    
  end
  
  def Base.add_sitter(uri, label)
    if !@@SITTERS.keys.include?(uri)
      @@SITTERS[uri] = label
    end
  end

  def Base.add_place(uri, label)
    if !@@PLACES.keys.include?(uri)
      @@PLACES[uri] = label
    end
  end      
end