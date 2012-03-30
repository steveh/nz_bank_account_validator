# -*- encoding: utf-8 -*-
require File.expand_path('../lib/validate_nz_bank_acc/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Eaden McKee"]
  gem.email         = ["eadz@eadz.co.nz"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "validate_nz_bank_acc"
  gem.require_paths = ["lib"]
  gem.version       = ValidateNzBankAcc::VERSION
  gem.add_development_dependency "rspec"
end
