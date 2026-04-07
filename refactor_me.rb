# Refactor by Mark Salvino
# Dino management refactored for clarity, maintainability, and testability
# I separated the spec into its own spec/ directory

class Dino
  attr_accessor :name, :category, :period, :diet, :age, :health, :comment, :age_metrics

  MAX_HEALTH = 100
  ALIVE = 'Alive'.freeze
  DEAD  = 'Dead'.freeze
  DIET_MATCH = { 'herbivore' => 'plants', 'carnivore' => 'meat' }.freeze

  def initialize(attrs)
    attrs = attrs.transform_keys(&:to_sym)
    @name        = attrs[:name]
    @category    = attrs[:category]
    @period      = attrs[:period]
    @diet        = attrs[:diet]
    @age         = attrs[:age]
    @health      = 0
    @comment     = ''
    @age_metrics = 0
  end

  def calculate_health
    return @health = 0 if @age.nil? || @age <= 0

    base = MAX_HEALTH - @age
    return @health = 0 if base <= 0

    correct_diet = DIET_MATCH[@category]
    return @health = 0 unless correct_diet  # unknown category → Dead

    @health = (@diet == correct_diet) ? base : (base / 2)
  end

  def set_comment
    @comment = @health > 0 ? ALIVE : DEAD
  end

  def calculate_age_metrics
    @age_metrics = (@comment == ALIVE && @age > 1) ? (@age / 2).to_i : 0
  end

  def process!
    calculate_health
    set_comment
    calculate_age_metrics
  end

  def to_h
    {
      name:        @name,
      category:    @category,
      period:      @period,
      diet:        @diet,
      age:         @age,
      health:      @health,
      comment:     @comment,
      age_metrics: @age_metrics
    }
  end
end

class DinoManager
  def initialize(dinos)
    @dinos = dinos.map { |d| Dino.new(d) }
  end

  def process_all
    @dinos.each(&:process!)
  end

  def summary
    @dinos.group_by(&:category).transform_values(&:count)
  end

  def result
    process_all
    { dinos: @dinos.map(&:to_h), summary: summary }
  end
end