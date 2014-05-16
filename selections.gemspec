# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'selections/version'

Gem::Specification.new do |gem|
  gem.name          = "selections"
  gem.version       = Selections::VERSION
  gem.authors       = ["Nigel Rausch"]
  gem.email         = ["nigelr@brisbanerails.com"]
  gem.description   = %q{Selection list management and form and view helpers.
 Manages one table to hold all selections items/dropdown lists ( tree ).
 Dynamic lookup to find parent or children ( eg. Selection.priorities ).
 Form helper to display lists ( eg. f.selections :priorities ).
 Handling of archived items ( displaying if selected only ).
}
  gem.summary       = %q{Selection list management and form and view helpers.
 Manages one table to hold all selections items/dropdown lists ( tree ).
 Dynamic lookup to find parent or children ( eg. Selection.priorities ).
 Form helper to display lists ( eg. f.selections :priorities ).
 Handling of archived items ( displaying if selected only ).
}
  gem.homepage      = "https://github.com/nigelr/selections"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('activesupport', ">= 3.0")
  gem.add_dependency('actionpack', ">= 3.0")
  gem.add_dependency 'acts_as_tree', '~> 1.6.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'nokogiri'
  gem.add_development_dependency 'shoulda-matchers', ">= 2.4.0"
end
