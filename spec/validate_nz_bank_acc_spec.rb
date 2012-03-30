require 'spec_helper'
describe ValidateNzBankAcc do

  let(:ex1) { ValidateNzBankAcc.new "01-0902-0068389-00" }
  let(:ex2) { ValidateNzBankAcc.new "08-6523-1954512-001" }
  let(:ex3) { ValidateNzBankAcc.new "26-2600-0320871-032" }

  describe "format" do
    let(:num) { " 03 0123-0034141-03" }
    it "should strip to just numbers and pad the suffix to 17 characters" do
      @v = ValidateNzBankAcc.new(num)
      @v.format
      @v.number.should == '03012300341410003'
      @v.number.length.should == 17
    end
  end

  describe "valid_bank_code?" do
    it "should check against BANKS for the bank code" do
      ValidateNzBankAcc.new("03-0123-0034141-03").valid_bank_code?.should be_true
      ValidateNzBankAcc.new("01-1113-0034141-03").valid_bank_code?.should be_true
      ValidateNzBankAcc.new("20-0123-1111111-11").valid_bank_code?.should be_true
      ValidateNzBankAcc.new("05-0123-0034141-03").valid_bank_code?.should be_false # no back 05
    end
  end

  describe "valid_bank_branch?" do
    it "should validate the branch code against the range of valid branches" do
      # VALIDS
      ValidateNzBankAcc.new("03-0123-0034141-03").valid_branch_code?.should be_true
      ValidateNzBankAcc.new("26-2600-0034141-03").valid_branch_code?.should be_true
      ValidateNzBankAcc.new("26-2699-0034141-0003").valid_branch_code?.should be_true
      ValidateNzBankAcc.new("11-6666-0034141-0003").valid_branch_code?.should be_true

      # INVALIDS
      ValidateNzBankAcc.new("11-1111-0034141-0003").valid_branch_code?.should be_false
      ValidateNzBankAcc.new("01-2012-0034141-0003").valid_branch_code?.should be_false
    end
  end

  describe "algo_code" do
    it "should select the correct algo_code code" do
      ValidateNzBankAcc.new("08-0123-0034141-03").algo_code.should == :d
      ValidateNzBankAcc.new("31-0123-0034141-03").algo_code.should == :x

      # If the account base number is below 00990000 then apply algorithm A, otherwise apply algorithm B
      ValidateNzBankAcc.new("30-0123-0034141-03").algo_code.should == :a
      ValidateNzBankAcc.new("30-0123-1034141-03").algo_code.should == :b
      ValidateNzBankAcc.new("30-0123-0990000-03").algo_code.should == :b
      #ValidateNzBankAcc.new("30-0123-0989999-03").algo_code.should == :a
    end
    it "should select the correct algo_code code according to the pdf" do
      ex1.algo_code.should == :a
      ex2.algo_code.should == :d
      ex3.algo_code.should == :g
    end
  end

  describe "number_18_char" do
    it "should zero pad the 7 digit account number to 8 characters" do
      ValidateNzBankAcc.new("08-0123-0034141-03").number_18_char.length.should == 18
      ValidateNzBankAcc.new("08-0123-0034141-03").number_18_char.should == '080123000341410003'
    end
  end

  describe "checksum_sum" do
    it "should return the same numbers as in the pdf" do
      ex1.checksum_sum.should == 176
      ex2.checksum_sum.should == 121
      ex3.checksum_sum.should == 30
    end
  end

  describe "valid_modulo?" do
    it "should valid modulo for the example in the pdf" do
      ex1.valid_modulo?.should be_true
      ex1.valid_modulo?.should be_true
      ex1.valid_modulo?.should be_true
    end
  end
end