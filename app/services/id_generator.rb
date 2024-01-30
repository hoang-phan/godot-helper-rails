class IdGenerator
  CHARS = %w[a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9].freeze
  CHAR_SIZE = CHARS.size

  attr_reader :counter

  def initialize(counter = 0)
    @counter = counter
  end

  def generate_str(length)
    val = rand(CHAR_SIZE ** length)
    result = ''

    length.times do |i|
      result << CHARS[val % CHAR_SIZE]
      val = val / CHAR_SIZE
    end

    result
  end

  def generate_id
    @counter += 1
    "#{counter}_#{generate_str(5)}"
  end

  def generate_uid
    "uid://#{generate_str(12)}"
  end
end
