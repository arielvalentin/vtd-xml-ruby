# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vtd_xml/version'

Gem::Specification.new do |spec|
  spec.name          = "vtd_xml"
  spec.version       = VtdXml::VERSION
  spec.authors       = ["Ariel S. Valentin", "Ryan A. Marone", "Ashraf M. Hanafy"]
  spec.email         = ["ariel@arielvalentin.com", "ashes42@gmail.com"]
  spec.description   = %q{I like VTD-XML so I use this instead of standard XML parsers}
  spec.summary   = %q{I like VTD-XML so I use this instead of standard XML parsers}
  spec.homepage      = "https://github.com/arielvalentin/vtd-xml-ruby"
  spec.license       = "MIT"
  spec.platform      = 'java'
  spec.files         =  Dir["**/*"].reject{ |path| path[%r{vendor|puppet}] }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "nokogiri"
end
