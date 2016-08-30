# NzBankAccountValidator

An implementation of the process described on page 10 of the [IRD RWT - NRWT 2008 Specification](https://www.ird.govt.nz/resources/d/8/d8e49dce-1bda-4875-8acf-9ebf908c6e17/rwt-nrwt-spec-2014.pdf).


## Installation

Add this line to your application's Gemfile:

```ruby
gem "nz_bank_account_validator"
```

And then execute:

    bundle

Or install it yourself as:

    gem install nz_bank_account_validator


## Usage

    NzBankAccountValidator.valid?(string)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/steveh/nz_bank_account_validator.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
