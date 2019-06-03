# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NzBankAccountValidator do
  def validator(string)
    NzBankAccountValidator.new(string)
  end

  let(:ex1) { validator('01-902-0068389-00') }
  let(:ex2) { validator('08-6523-1954512-001') }
  let(:ex3) { validator('26-2600-0320871-032') }

  it 'has a version number' do
    expect(NzBankAccountValidator::VERSION).not_to be nil
  end

  describe '#valid_bank_id?' do
    it 'should validate the bank id' do
      expect(validator('03-0123-0034141-03')).to be_valid_bank_id
      expect(validator('01-1113-0034141-03')).to be_valid_bank_id
      expect(validator('20-0123-1111111-11')).to be_valid_bank_id
      expect(validator('05-0123-0034141-03')).to_not be_valid_bank_id # no back 05
    end
  end

  describe '#valid_bank_branch?' do
    it 'should validate the branch code against the range of valid branches' do
      # VALIDS
      expect(validator('03-0123-0034141-03')).to be_valid_bank_branch
      expect(validator('26-2600-0034141-03')).to be_valid_bank_branch
      expect(validator('26-2699-0034141-0003')).to be_valid_bank_branch
      expect(validator('11-6666-0034141-0003')).to be_valid_bank_branch

      # INVALIDS
      expect(validator('11-1111-0034141-0003')).to_not be_valid_bank_branch
      expect(validator('01-2012-0034141-0003')).to_not be_valid_bank_branch
    end
  end

  describe '#algo_code' do
    it 'should select the correct algo_code code' do
      expect(validator('08-0123-0034141-03').algo_code).to eq(:d)
      expect(validator('31-0123-0034141-03').algo_code).to eq(:x)

      # If the account base number is below 00990000 then apply algorithm A, otherwise apply algorithm B
      expect(validator('30-0123-0034141-03').algo_code).to eq(:a)
      expect(validator('30-0123-1034141-03').algo_code).to eq(:b)
      expect(validator('30-0123-0990000-03').algo_code).to eq(:b)
      expect(validator('30-0123-0989999-03').algo_code).to eq(:a)
    end

    it 'should select the correct algo_code code according to the pdf' do
      expect(ex1.algo_code).to eq(:a)
      expect(ex2.algo_code).to eq(:d)
      expect(ex3.algo_code).to eq(:g)
    end
  end

  describe '#number_for_checksum' do
    it 'should zero pad the 7 digit account number to 8 characters' do
      expect(validator('08-0123-0034141-03').number_for_checksum).to eq('080123000341410003')
    end
  end

  describe '#checksum' do
    it 'should return the same numbers as in the pdf' do
      expect(ex1.checksum).to eq(176)
      expect(ex2.checksum).to eq(121)
      expect(ex3.checksum).to eq(30)
    end
  end

  describe '#valid_modulo?' do
    it 'should valid modulo for the example in the pdf' do
      expect(ex1).to be_valid_modulo
      expect(ex1).to be_valid_modulo
      expect(ex1).to be_valid_modulo
    end
  end

  describe '#valid?' do
    it 'instance method' do
      expect(NzBankAccountValidator.new('08-6523-1954512-001')).to be_valid
    end

    it 'class method' do
      expect(NzBankAccountValidator.valid?('08-6523-1954512-001')).to eq(true)
    end
  end
end
