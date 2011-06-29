# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack/geo/version"

Gem::Specification.new do |s|
  s.name        = "rack-geo"
  s.version     = Rack::Geo::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Randy Reddig", "Cameron Walters", "Paul McKellar"]
  s.email       = "github@squareup.com"
  s.homepage    = "https://github.com/square/rack-geo"
  s.summary     = %q{Rack middleware for Geo-Position HTTP headers}
  s.description = %q{Parse and serialize geospatial HTTP headers.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.extra_rdoc_files = ['README.rdoc', 'HISTORY.rdoc', 'LICENSE.txt']
  s.require_paths = ["lib"]

  s.add_dependency 'rack', '~> 1.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rack-test', '~> 0.5'
  s.add_development_dependency 'rspec', '1.3.0'
end
