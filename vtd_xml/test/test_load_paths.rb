ENV['RACK_ENV'] = 'test'
require 'java'
require 'rubygems'

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

jars = File.expand_path('../../vendor/jars', __FILE__)
$LOAD_PATH.unshift(jars) unless $LOAD_PATH.include?(jars)

test = File.expand_path('../../test', __FILE__)
$LOAD_PATH.unshift(test) unless $LOAD_PATH.include?(test)

require 'bundler/setup'
Bundler.require(:test)

require 'test/unit'
require 'nokogiri'
require 'shoulda-context'
