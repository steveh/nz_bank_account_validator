require "nz_bank_account_validator/version"

# frozen_string_literal: true
class NzBankAccountValidator
  PATTERN = /\A^(?<bank_id>\d{1,2})[- ]?(?<bank_branch>\d{1,4})[- ]?(?<account_base_number>\d{1,8})[- ]?(?<account_suffix>\d{1,4})\z/

  RADIX = 10

  CHECKSUM_DIGITS = 18

  ACCOUNT_BASE_NUMBER_CUTOFF = 990000

  BANKS = { 1 => { ranges: [1..999, 1100..1199, 1800..1899] },
            2 => { ranges: [1..999, 1200..1299] },
            3 => { ranges: [1..999, 1300..1399, 1500..1599, 1700..1799, 1900..1999] },
            6 => { ranges: [1..999, 1400..1499] },
            8 => { ranges: [6500..6599], algo: :d },
            9 => { ranges: [], algo: :e }, # range was 0000
            11 => { ranges: [5000..6499, 6600..8999] },
            12 => { ranges: [3000..3299, 3400..3499, 3600..3699] },
            13 => { ranges: [4900..4999] },
            14 => { ranges: [4700..4799] },
            15 => { ranges: [3900..3999] },
            16 => { ranges: [4400..4499] },
            17 => { ranges: [3300..3399] },
            18 => { ranges: [3500..3599] },
            19 => { ranges: [4600..4649] },
            20 => { ranges: [4100..4199] },
            21 => { ranges: [4800..4899] },
            22 => { ranges: [4000..4049] },
            23 => { ranges: [3700..3799] },
            24 => { ranges: [4300..4349] },
            25 => { ranges: [2500..2599], algo: :f },
            26 => { ranges: [2600..2699], algo: :g },
            27 => { ranges: [3800..3849] },
            28 => { ranges: [2100..2149], algo: :g },
            29 => { ranges: [2150..2299], algo: :g },
            30 => { ranges: [2900..2949] },
            31 => { ranges: [2800..2849], algo: :x },
            33 => { ranges: [6700..6799], algo: :f },
            35 => { ranges: [2400..2499] },
            38 => { ranges: [9000..9499] } }.freeze

  ALGOS = {
    a: [0, 0, 6, 3, 7, 9, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
    b: [0, 0, 0, 0, 0, 0, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
    c: [3, 7, 0, 0, 0, 0, 9, 1, 10, 5, 3, 4, 2, 1, 0, 0, 0, 0, 11],
    d: [0, 0, 0, 0, 0, 0, 0, 7,  6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 11],
    e: [0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 5, 4, 3, 2, 0, 0, 0, 1, 11],
    f: [0, 0, 0, 0, 0, 0, 0, 1,  7, 3, 1, 7, 3, 1, 0, 0, 0, 0, 10],
    g: [0, 0, 0, 0, 0, 0, 0, 1,  3, 7, 1, 3, 7, 1, 0, 3, 7, 1, 10],
    x: [0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  1],
  }.freeze

  def self.valid?(string)
    new(string).valid?
  end

  def initialize(string)
    match = string.match(PATTERN)

    if match
      @bank_id = Integer(match[:bank_id], RADIX)
      @bank_branch = Integer(match[:bank_branch], RADIX)
      @account_base_number = Integer(match[:account_base_number], RADIX)
      @account_suffix = Integer(match[:account_suffix], RADIX)
    end
  end

  attr_accessor :bank_id, :bank_branch, :account_base_number, :account_suffix

  def valid?
    return false unless valid_bank_id?
    return false unless valid_bank_branch?
    return false unless account_base_number
    return false unless account_suffix
    return false unless valid_modulo?
    true
  end

  def valid_bank_id?
    return false unless bank_id

    BANKS.key?(bank_id)
  end

  def valid_bank_branch?
    return false unless valid_bank_id?
    return false unless bank_branch

    if BANKS[bank_id][:ranges].empty?
      # Bank 9. Anything is valid? # TODO: confirm
      true
    else
      BANKS[bank_id][:ranges].any? do |range|
        range.include?(bank_branch)
      end
    end
  end

  def valid_modulo?
    (checksum % algo[CHECKSUM_DIGITS]).zero?
  end

  def algo_code
    # If the account base number is below 00990000 then apply algorithm A
    # Otherwise apply algorithm B.
    BANKS[bank_id][:algo] || (account_base_number < ACCOUNT_BASE_NUMBER_CUTOFF ? :a : :b)
  end

  def algo
    ALGOS[algo_code]
  end

  def number_for_checksum
    format("%02d%04d%08d%04d", bank_id, bank_branch, account_base_number, account_suffix)
  end

  def checksum
    if [:e, :g].include?(algo_code)
      (0...CHECKSUM_DIGITS).inject(0) do |sum, index|
        s = number_for_checksum[index].to_i * algo[index]
        2.times { s = s.to_s.chars.map(&:to_i).inject(:+) }
        sum + s
      end
    else
      (0...CHECKSUM_DIGITS).inject(0) do |sum, index|
        sum + number_for_checksum[index].to_i * algo[index]
      end
    end
  end
end
