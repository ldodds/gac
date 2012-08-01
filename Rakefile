require 'rubygems'
require 'rake'
require 'rake/clean'

CACHE_DIR="data/cache"
RDF_DIR="data/nt"

CLEAN.include ["#{RDF_DIR}/*.nt", "#{RDF_DIR}/*.gz"]

#Helper function to create data dirs
def mkdirs()
  if !File.exists?("data")
    Dir.mkdir("data")
  end  
  if !File.exists?(CACHE_DIR)
    Dir.mkdir(CACHE_DIR)
  end
  if !File.exists?(RDF_DIR)
    Dir.mkdir(RDF_DIR)
  end
end

task :init do
  mkdirs()
end

task :gen_artist_index do
  sh %{ruby bin/gen_artist_index.rb #{CACHE_DIR}}  
end

task :gen_work_index do
  sh %{ruby bin/gen_work_index.rb #{CACHE_DIR}}  
  sh %{sort #{CACHE_DIR}/works.txt | uniq > #{CACHE_DIR}/works-final.txt}
  sh %{mv #{CACHE_DIR}/works-final.txt #{CACHE_DIR}/works.txt}
end

task :cache do
  sh %{ruby bin/crawler.rb #{CACHE_DIR}}
end

task :crawl => [:gen_artist_index, :gen_work_index, :cache]

task :convert_static do
  Dir.glob("etc/static/*.ttl").each do |src|
      sh %{rapper -i turtle -o ntriples #{src} >#{RDF_DIR}/#{File.basename(src, ".ttl")}.nt}
  end
end

task :convert_works do
  sh %{ruby bin/convert_works.rb #{CACHE_DIR} #{RDF_DIR}}
end

task :convert_subjects do
  sh %{ruby bin/convert_subjects.rb #{RDF_DIR}}
end

task :reconcile_places do
  sh %{ruby bin/reconcile_places.rb #{RDF_DIR} #{RDF_DIR}}
end

task :reconcile_sitters do
  sh %{ruby bin/reconcile_sitters.rb #{RDF_DIR} #{RDF_DIR}}
end
  
task :convert => [:init, :convert_works, :convert_subjects, :convert_static]

task :reconcile => [:reconcile_sitters, :reconcile_places]

task :package do
  sh %{gzip #{RDF_DIR}/*.nt} 
end

task :publish => [:crawl, :convert, :package]