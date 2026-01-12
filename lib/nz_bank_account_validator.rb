# frozen_string_literal: true

require "nz_bank_account_validator/version"

class NzBankAccountValidator
  class BankDefinition
    def initialize(ranges: [], algo: nil)
      @ranges = ranges
      @algo = algo
    end

    attr_reader :algo

    def include?(branch)
      @ranges.any? do |range|
        range.include?(branch)
      end
    end
  end

  PATTERN = /\A^(?<bank_id>\d{1,2})[- ]?(?<bank_branch>\d{1,4})[- ]?(?<account_base_number>\d{1,8})[- ]?(?<account_suffix>\d{1,4})\z/.freeze

  RADIX = 10

  CHECKSUM_DIGITS = 18

  ACCOUNT_BASE_NUMBER_CUTOFF = 990_000

  BANKS = {
    1  => BankDefinition.new(ranges: [1..999, 1100..1199, 1800..1899]),
    2  => BankDefinition.new(ranges: [1..999, 1200..1299]),
    3  => BankDefinition.new(ranges: [1..999, 1300..1399, 1500..1599, 1700..1799, 1900..1999, 7350..7399]),
    4  => BankDefinition.new(ranges: [2014..2024]),
    6  => BankDefinition.new(ranges: [1..999, 1400..1499]),
    8  => BankDefinition.new(ranges: [6500..6599], algo: :d),
    9  => BankDefinition.new(ranges: [0..0], algo: :e),
    10 => BankDefinition.new(ranges: [5165..5169]),
    11 => BankDefinition.new(ranges: [5000..6499, 6600..8999]),
    12 => BankDefinition.new(ranges: [3000..3299, 3400..3499, 3600..3699]),
    13 => BankDefinition.new(ranges: [4900..4999]),
    14 => BankDefinition.new(ranges: [4700..4799]),
    15 => BankDefinition.new(ranges: [3900..3999]),
    16 => BankDefinition.new(ranges: [4400..4499]),
    17 => BankDefinition.new(ranges: [3300..3399]),
    18 => BankDefinition.new(ranges: [3500..3599]),
    19 => BankDefinition.new(ranges: [4600..4649]),
    20 => BankDefinition.new(ranges: [4100..4199]),
    21 => BankDefinition.new(ranges: [4800..4899]),
    22 => BankDefinition.new(ranges: [4000..4049]),
    23 => BankDefinition.new(ranges: [3700..3799]),
    24 => BankDefinition.new(ranges: [4300..4349]),
    25 => BankDefinition.new(ranges: [2500..2599], algo: :f),
    26 => BankDefinition.new(ranges: [2600..2699], algo: :g),
    27 => BankDefinition.new(ranges: [3800..3849]),
    28 => BankDefinition.new(ranges: [2100..2149], algo: :g),
    29 => BankDefinition.new(ranges: [2150..2299], algo: :g),
    30 => BankDefinition.new(ranges: [2900..2949]),
    31 => BankDefinition.new(ranges: [2800..2849], algo: :x),
    33 => BankDefinition.new(ranges: [6700..6799], algo: :f),
    35 => BankDefinition.new(ranges: [2400..2499]),
    38 => BankDefinition.new(ranges: [9000..9499]),
  }.freeze

  ALGOS = {
    a: [0, 0, 6, 3, 7, 9, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
    b: [0, 0, 0, 0, 0, 0, 0, 0, 10, 5, 8, 4, 2, 1, 0, 0, 0, 0, 11],
    c: [3, 7, 0, 0, 0, 0, 9, 1, 10, 5, 3, 4, 2, 1, 0, 0, 0, 0, 11],
    d: [0, 0, 0, 0, 0, 0, 0, 7,  6, 5, 4, 3, 2, 1, 0, 0, 0, 0, 11],
    e: [0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 5, 4, 3, 2, 0, 0, 0, 1, 11],
    f: [0, 0, 0, 0, 0, 0, 0, 1,  7, 3, 1, 7, 3, 1, 0, 0, 0, 0, 10],
    g: [0, 0, 0, 0, 0, 0, 0, 1,  3, 7, 1, 3, 7, 1, 0, 3, 7, 1, 10],
    x: [0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  }.freeze

  def self.valid?(string)
    new(string).valid?
  end

  def initialize(string)
    match = string.match(PATTERN)
    return unless match

    @bank_id = Integer(match[:bank_id], RADIX)
    @bank_branch = Integer(match[:bank_branch], RADIX)
    @account_base_number = Integer(match[:account_base_number], RADIX)
    @account_suffix = Integer(match[:account_suffix], RADIX)
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
    return false unless bank_definition
    return false unless bank_branch

    bank_definition.include?(bank_branch)
  end

  def valid_modulo?
    (checksum % algo[CHECKSUM_DIGITS]).zero?
  end

  def bank_definition
    BANKS[bank_id]
  end

  def algo
    ALGOS[algo_code]
  end

  def algo_code
    # If the account base number is below 00990000 then apply algorithm A
    # Otherwise apply algorithm B.
    bank_definition.algo || (account_base_number < ACCOUNT_BASE_NUMBER_CUTOFF ? :a : :b)
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
