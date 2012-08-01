require 'rubygems'
require 'hpricot'
require 'Base'

class Work < Base
  
  attr_reader :statements, :fields
  
  def initialize(id, html)
    @id = id
    @doc = Hpricot(html)
    @statements = []

    if @doc.at("title").inner_text() == "Government Art Collection - Error page"
      raise "Error page, not content"
    end
    
    @fields = {}
    @doc.search("#detailsArtWork table tr").each do |row|
      key = row.children[0].inner_text
      value = row.children[1]
      if key != ""
        if @fields[key] == nil
          @fields[key] = []
        end
        if value.at("a") != nil
          @fields[key] << value.at("a")
        else
          @fields[key] << value.inner_text
        end
      end
      
    end        
    
    description = @doc.at("#contentWorkDescription")
    @fields[:description] = description.inner_text if description
      
    @fields[:subjects] = []
    @doc.search("#contentWorkSubjects li a") do |subject|
      @fields[:subjects] << subject
    end

    biography = @doc.at("#contentWorkMakerBiography")
    @fields[:biography] = biography if biography

    img = @doc.at("#zoomImage img")
    @fields[:img] = img["src"] if img

    if @doc.at("#zoomDetails p").children && @doc.at("#zoomDetails p").children.length == 6
      @fields[:copyright] = @doc.at("#zoomDetails p").children[3]
    end
           
    @fields[:places] = []
    @doc.search("#contentWorkPlaces li a") do |place|
      @fields[:places] << place
    end
    
    @fields[:sitters] = []
    @doc.search("#contentWorkSitters li a") do |sitter|
      @fields[:sitters] << sitter
    end    
        
#    if @fields["GAC number"] == nil
#      raise "No GAC number?"
#    end
    
    @uri = uri("/works/#{@id}")
    
    generate_statements()
    
  end  
  
  SPECIAL_CASE = ["Title", "Date", "GAC number", "Artist", "Manufacturer", "Engraver", 
    "Founder/Foundry",
    "Lithographer", "Photographer", "Copyist", "Foundry", "Publisher", "Poet", "Maker",
    "Designer", "Weaver", "Author", "Architect",
      :description, :biography, :places, :subjects, :sitters, :img, :copyright]
    
  def generate_statements()
    add_property( RDF.type, GAC.ArtWork )
    
    #identifiers and homepage
    add_property( RDF::DC.identifier, @fields["GAC number"])      
    add_property( GAC.number, @fields["GAC number"])
    add_property( RDF::FOAF.page, 
      RDF::URI.new("http://www.gac.culture.gov.uk/work.aspx?obj=#{@id}"))
      
    #description
    add_property( RDF::DC.title, @fields["Title"])
    add_property( RDF::DC.description, @fields[:description])
    add_property( RDF::DC.date, @fields["Date"] )
            
    #pass through anything not special cased as part of custom schema
    @fields.keys.each do |field|
      if !SPECIAL_CASE.include?(field)        
        declare_property( field )
        add_property( GAC[property_name(field)], @fields[field])
      end
    end        
    
    ["Artist", "Engraver", "Photographer", "Copyist", "Lithographer", "Maker",
      "Foundry", "Founder/Foundry", "Publisher", "Poet", "Designer", "Weaver", "Author", "Architect"].each do |agent_field|
      if @fields[agent_field]
        @fields[agent_field].each do |artist|
          if agent_field == "Founder/Foundry"
            agent_field = "Foundry"
          end
          #if artist.inner_text != "unknown"
            artist_id = link_id( artist , "id")
            artist_uri = uri( "/artists/#{artist_id}")
            @statements << RDF::Statement.new( artist_uri, RDF.type, GAC[agent_field] )
            @statements << RDF::Statement.new( artist_uri, RDF::RDFS.label, artist.inner_text )
            @statements << RDF::Statement.new( artist_uri, RDF::FOAF.name, artist.inner_text )
            @statements << RDF::Statement.new( artist_uri, GAC.number, artist_id )
  
            #generic maker/made relationship
            @statements << RDF::Statement.new( artist_uri, RDF::FOAF.made, @uri )
            add_property( RDF::FOAF.maker, artist_uri )
                             
            declare_property( agent_field )
            declare_type( agent_field )
            add_property( GAC[property_name(agent_field)], artist_uri )          
          #end
        end      
      end
      
    end
            
    if @fields[:biography]
      #may have >1 biography
      #first p contains link with artist id, following p, contains their bio
      @fields[:biography].search("p.contentWork") do |para|
        artist_id = link_id( para.at("a"), "id" )
        artist_uri = uri( "/artists/#{artist_id}")
        @statements << RDF::Statement.new( artist_uri, RDF::DC.description, para.next.inner_text )
      end
    end
    
    if @fields[:img]
      img_uri = RDF::URI.new( "http://www.gac.culture.gov.uk#{@fields[:img]}" )
      thumbnail_uri = RDF::URI.new( 
        "http://www.gac.culture.gov.uk#{@fields[:img].gsub("standard", "thumbnail")}" )
      
      @statements << RDF::Statement.new( img_uri, RDF.type, RDF::FOAF.Image )
      @statements << RDF::Statement.new( thumbnail_uri, RDF.type, RDF::FOAF.Image )
      @statements << RDF::Statement.new( img_uri, RDF::FOAF.depicts, @uri)
      @statements << RDF::Statement.new( img_uri, RDF::FOAF.thumbnail, thumbnail_uri )
      @statements << RDF::Statement.new( img_uri, RDF::RDFS.label, @fields["Title"])
                
      if @fields[:copyright]
        @statements << RDF::Statement.new( img_uri, RDF::DC.license, @fields[:copyright])
      end
      
      add_property( RDF::FOAF.depiction, img_uri)
      
    end
    
    if @fields[:subjects]
      @fields[:subjects].each do |link|
        subject_id = link_id( link , "tid")
        subject_uri = uri( "/subjects/#{subject_id}")
        #Only include subject uri to work around issues with subject tags on 
        #the GAC site: some have missing text and/or wrong ids
        add_property( RDF::DC.subject, subject_uri )
      end  
    end  

    if @fields[:places]
      @fields[:places].each do |link|
        place_id = link_id( link , "pid")
        place_uri = uri( "/places/#{place_id}")
        label = link.inner_text.rstrip.gsub(/,$/, "")
        Base.add_place(place_uri, label)
        @statements << RDF::Statement.new( place_uri, RDF.type, 
          RDF::URI.new("http://www.geonames.org/ontology#Feature") )
        @statements << RDF::Statement.new( place_uri, RDF::RDFS.label, label )
        add_property( GAC.place, place_uri )
      end  
    end       
       
    if @fields[:sitters]
      @fields[:sitters].each do |link|
        sitter_id = link_id( link , "sid")
        sitter_uri = uri( "/sitters/#{sitter_id}")
        label = link.inner_text.rstrip.gsub(/,$/, "")
        Base.add_sitter(sitter_uri, label)
        @statements << RDF::Statement.new( sitter_uri, RDF.type, RDF::FOAF.Agent )
        @statements << RDF::Statement.new( sitter_uri, RDF::RDFS.label, label )
        @statements << RDF::Statement.new( sitter_uri, GAC.depiction, @uri)
        add_property( GAC.depicts, sitter_uri )
      end  
    end
    
    if @fields["Dimensions"]
      match = @fields["Dimensions"][0].match(/height: ([0-9\.]+) cm(, width: ([0-9\.]+) cm(, depth: ([0-9\.]+))?)?/)
      if match
        height = match[1]
        width = match[3]
        depth = match[5]

        add_property( MEASURE.height, 
          RDF::Literal.new(height, :datatype => RDF::XSD.float))
        add_property( MEASURE.width,  
          RDF::Literal.new(width, :datatype => RDF::XSD.float)) if width          
        add_property( MEASURE.depth,  
          RDF::Literal.new(depth, :datatype => RDF::XSD.float)) if depth
       
      end          
    end
    
    #TODO
    #Parse out locations and geocode?
    
  end
  
end