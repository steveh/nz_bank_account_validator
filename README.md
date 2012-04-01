# ValidateNzBankAcc

An implementation of the process described on page 15 of
http://www.ird.govt.nz/resources/a/c/ac60890040b57d0e9bd4df41f9f3ce1d/rwt-nrwt-spec-2010-v3.pdf

## Installation

Add this line to your application's Gemfile:

    gem 'validate_nz_bank_acc'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install validate_nz_bank_acc

## Usage

  ValidateNzBankAcc.new(bank_id, branch_id, account_number, suffix).valid?

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
