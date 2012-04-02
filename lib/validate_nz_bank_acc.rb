require "validate_nz_bank_acc/version"

class ValidateNzBankAcc

  BANKS = { 1 => {:ranges => [1..999, 1100..1199, 1800..1899]},
            2 => {:ranges => [1..999, 1200..1299]},
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
  attr_accessor :bank_id, :branch_id, :account_number, :suffix
  def initialize(bank_id, branch_id, account_number, suffix)
    @bank_id = process_input(bank_id)
    @branch_id = process_input(branch_id)
    @account_number = process_input(account_number)
    @suffix = process_input(suffix)
  end

  def valid?
    valid_branch_code? && valid_modulo?
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
    BANKS[bank_id][:algo] || (account_number < 990000 ? :a : :b)
  end

  def algo
    ALGOS[algo_code]
  end

  def checksum_sum
    if [:e, :g].include? algo_code
      (0..17).inject(0) do |sum, index|
        s = number[index].to_i * algo[index]
        2.times { s = s.to_s.chars.map(&:to_i).inject(:+) }
        sum += s
      end
    else
      (0..17).inject(0) {|sum, index| sum += number[index].to_i * algo[index]; sum }
    end
  end

  def valid_modulo?
    checksum_sum % algo[18] == 0
  end

  def number # account number padded to 8 chars
    bank_code + branch_code + account_number_code + suffix_code
  end

  private

    def bank_code
      @bank_id.to_s.rjust(2,'0')
    end

    def branch_code
      @branch_id.to_s.rjust(4,'0')
    end

    def account_number_code
      @account_number.to_s.rjust(8,'0')
    end

    def suffix_code
      @suffix.to_s.rjust(4,'0')
    end

    def process_input(num)
      num.to_s.gsub(/[^0-9]/,'').to_i
    end
end
