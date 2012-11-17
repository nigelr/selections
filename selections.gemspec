# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'selections/version'

Gem::Specification.new do |gem|
  gem.name          = "selections"
  gem.version       = Selections::VERSION
  gem.authors       = ["Nigel Rausch"]
  gem.email         = ["nigelr@brisbanerails.com"]
  gem.description   = %q{Selections provides a minimal set of tools for database-backed lists of select options.}
  gem.summary       = %q{Database backed select options... of doom!}
  gem.homepage      = ""
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord', '~> 3.0'
  gem.add_dependency 'actionpack',   '~> 3.0'
  gem.add_dependency 'acts_as_tree', '~> 1.2.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'reversible_data'

end
