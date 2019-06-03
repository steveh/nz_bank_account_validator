# frozen_string_literal: true

require "nz_bank_account_validator/version"

class NzBankAccountValidator
  BankDefinition = Struct.new(:ranges, :algo)

  PATTERN = /\A^(?<bank_id>\d{1,2})[- ]?(?<bank_branch>\d{1,4})[- ]?(?<account_base_number>\d{1,8})[- ]?(?<account_suffix>\d{1,4})\z/.freeze

  RADIX = 10

  CHECKSUM_DIGITS = 18

  ACCOUNT_BASE_NUMBER_CUTOFF = 990_000

  BANKS = {
    1  => BankDefinition.new([1..999, 1100..1199, 1800..1899]),
    2  => BankDefinition.new([1..999, 1200..1299]),
    3  => BankDefinition.new([1..999, 1300..1399, 1500..1599, 1700..1799, 1900..1999]),
    6  => BankDefinition.new([1..999, 1400..1499]),
    8  => BankDefinition.new([6500..6599], :d),
    9  => BankDefinition.new([0..0], :e),
    11 => BankDefinition.new([5000..6499, 6600..8999]),
    12 => BankDefinition.new([3000..3299, 3400..3499, 3600..3699]),
    13 => BankDefinition.new([4900..4999]),
    14 => BankDefinition.new([4700..4799]),
    15 => BankDefinition.new([3900..3999]),
    16 => BankDefinition.new([4400..4499]),
    17 => BankDefinition.new([3300..3399]),
    18 => BankDefinition.new([3500..3599]),
    19 => BankDefinition.new([4600..4649]),
    20 => BankDefinition.new([4100..4199]),
    21 => BankDefinition.new([4800..4899]),
    22 => BankDefinition.new([4000..4049]),
    23 => BankDefinition.new([3700..3799]),
    24 => BankDefinition.new([4300..4349]),
    25 => BankDefinition.new([2500..2599], :f),
    26 => BankDefinition.new([2600..2699], :g),
    27 => BankDefinition.new([3800..3849]),
    28 => BankDefinition.new([2100..2149], :g),
    29 => BankDefinition.new([2150..2299], :g),
    30 => BankDefinition.new([2900..2949]),
    31 => BankDefinition.new([2800..2849], :x),
    33 => BankDefinition.new([6700..6799], :f),
    35 => BankDefinition.new([2400..2499]),
    38 => BankDefinition.new([9000..9499])
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
