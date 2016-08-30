# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nz_bank_account_validator/version"

Gem::Specification.new do |spec|
  spec.name          = "nz_bank_account_validator"
  spec.version       = NzBankAccountValidator::VERSION
  spec.authors       = ["Steve Hoeksema", "Eaden McKee"]
  spec.email         = ["steve@kotiri.com"]
  spec.summary       = "Validate a New Zealand bank account number according to IRD specifications"
  spec.description   = "Validate a New Zealand bank account number according to IRD specifications"
  spec.homepage      = "https://github.com/steveh/nz_bank_account_validator"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
