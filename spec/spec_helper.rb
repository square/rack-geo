require 'rubygems'

$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'rack-geo'
require 'spec/expectations'
require 'rack/test'
