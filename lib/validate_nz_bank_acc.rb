require "validate_nz_bank_acc/version"
# ASSUMPTIONS!
# bank code zero-padded to two chars
# branch code zero-padded to four chars
# account number zero-padded to seven characters # 8 character bank account numbers
# while valid, are not used in NZ. I think. This works with 7 char account numbers
# account suffix can be 1-4 chars, zero padded
class ValidateNzBankAcc

  BANKS = { 1 => {:ranges => [1..999, 1100...1199]},
            2 => {:ranges => [1..999, 1200.1299]},
            3 => {:ranges => [1..999, 1300..1399, 1500..1599, 1700..1799, 1900..1999]},
            6 => {:ranges => [1..999, 1400..1499]},
            8 => {:ranges => [6500..6599], :algo => :d},
            9 => {:ranges => [], :algo => :e}, # range was 0000
            11 => {:ranges => [5000..6499, 6600..8999]},
            12 => {:ranges => [3000..3299, 3400..3499,3600..3699]},
            13 => {:ranges => [4900..4999]},
            14 => {:ranges => [4700..4799]},
            15 => {:ranges => [3900..3999]},
            16 => {:ranges => [4400..4499]},
            17 => {:ranges => [3300..3399]},
            18 => {:ranges => [3500..3599]},
            19 => {:ranges => [4600..4649]},
            20 => {:ranges => [4100..4199]},
            22 => {:ranges => [4000..4049]},
            23 => {:ranges => [3700..3799]},
            24 => {:ranges => [4300..4349]},
            25 => {:ranges => [2500..2599], :algo => :f},
            26 => {:ranges => [2600..2699], :algo => :g},
            27 => {:ranges => [3800..3849]},
            28 => {:ranges => [2100..2149], :algo => :g},
            29 => {:ranges => [2150..2299], :algo => :g},
            30 => {:ranges => [2900..2949]},
            31 => {:ranges => [2800..2849], :algo => :x},
            33 => {:ranges => [6700..6799], :algo => :f},
            35 => {:ranges => [2400..2499]},
            38 => {:ranges => [9000..9499]}
          }

  ALGOS = {
           :a =>[0, 0, 6, 3, 7, 9, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
           :b => [0, 0, 0, 0, 0, 0, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
           :c => [3, 7, 0, 0, 0, 0, 9, 1, 10, 5, 3, 4, 2, 1, 0, 0, 0, 0, 11],
           :d => [0, 0, 0, 0, 0, 0, 0, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 11],
           :e => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 4, 3, 2, 0, 0, 0, 1, 11],
           :f => [ 0, 0, 0, 0, 0, 0, 0, 1, 7, 3, 1, 7, 3, 1, 0, 0, 0, 0, 10],
           :g => [0, 0, 0, 0, 0, 0, 0, 1, 3, 7, 1, 3, 7, 1, 0, 3, 7, 1, 10],
           :x => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
          }
  attr_accessor :number
  attr_accessor :orig_number

  def initialize(number)
    @number = number.to_s.dup
    @orig_number = @number.dup
    @errors = []
    pre_validate
  end

  def valid?
    @errors.empty?
  end

  def format
    @formatted = true
    @number = @number.strip.gsub(/[^0-9]/,'')
    @number = @number[0..12] + @number[13..16].rjust(4,'0')
  end

  # VALIDATIONS
  def correct_length?
    # 03 0432 1234567 01 - 03 0432 1234567 1111 # suffix can be 4 but usually 2-3
    @number.length == 17
  end

  def valid_bank_code?
    BANKS.has_key? bank_id
  end

  def valid_branch_code?
    return false unless valid_bank_code?
    if BANKS[bank_id][:ranges].empty?
      # Bank 9. Anything is valid? # DOUBLE CHECK
      true
    else
      BANKS[bank_id][:ranges].any? do |range|
        range.include? branch_id
      end
    end
  end

  def algo_code
    # If the account base number is below 00990000 then apply algorithm A, otherwise apply algorithm B.
    BANKS[bank_id][:algo] || (account_id < 990000 ? :a : :b)
  end

  def algo
    ALGOS[algo_code]
  end

  def checksum_sum
    if [:e, :g].include? algo_code
      (0..17).inject(0) do |sum, index|
        s = number_18_char[index].to_i * algo[index]
        2.times { s = s.to_s.chars.map(&:to_i).inject(:+) }
        sum += s
      end
    else
      (0..17).inject(0) {|sum, index| sum += number_18_char[index].to_i * algo[index]; sum }
    end
  end

  def valid_modulo?
    checksum_sum % algo[18] == 0
  end

  def number_18_char # account number padded to 8 chars
    bank_code + branch_code + '0' + account_code + suffix_code
  end
  private

    def pre_validate
      format
    end

    def bank_code
      @number[0..1]
    end

    def bank_id
      bank_code.to_i
    end

    def branch_code
      @number[2..5]
    end

    def branch_id
      branch_code.to_i
    end

    def account_code
      @number[6..13]
    end

    def account_id
      account_code.to_i
    end

    def suffix_code
      @number[14..17]
    end

    def suffix_id
      suffix_code.to_i
    end
end
