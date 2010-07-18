require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

require File.join(File.dirname(__FILE__), 'lib', 'rack', 'geo', 'version')

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.version = Rack::Geo::VERSION::STRING
    gemspec.name = "rack-geo"
    gemspec.summary = "Rack middleware for Geo-Position HTTP headers"
    gemspec.description = "Parse and serialize geospatial HTTP headers."
    gemspec.email = "github@squareup.com"
    gemspec.homepage = "http://github.com/square/rack-geo"
    gemspec.authors = [
      "Randy Reddig",
      "Cameron Walters",
      "Paul McKellar",
    ]
    gemspec.extra_rdoc_files = [
      'README.rdoc',
      'HISTORY.rdoc',
      'LICENSE.txt',
    ]
    gemspec.add_dependency              "rack",         ">=1.0.0"
    gemspec.add_development_dependency  "rack-test",    ">=0.5.3"
    gemspec.add_development_dependency  "rspec",        ">=1.3.0"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ["--options", "spec/spec.opts"]
  t.spec_files = FileList["spec/**/*_spec.rb"]
  t.rcov = ENV["RCOV"]
  t.rcov_opts = %w{--exclude osx\/objc,gems\/,spec\/}
  t.verbose = true
end

task :spec => :check_dependencies
task :default => :spec

desc "Remove trailing whitespace"
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end
