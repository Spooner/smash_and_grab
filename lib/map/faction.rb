class Faction
  # Super-villains
  class Baddies < self
    COLOR = Color.rgb(255, 50, 50)
  end

  # Superheroes, police, g-men, etc.
  class Goodies < self
    COLOR = Color.rgb(100, 100, 255)
    def friend?(faction); (faction.is_a? Bystanders) or super; end
  end

  # Everyone else (NPCS).
  class Bystanders < self
    COLOR = Color.rgb(255, 255, 0)

    def friend?(faction); (faction.is_a? Goodies) or super; end
  end

  # -----------------------------------------------

  include Fidgit::Event
  extend Forwardable
  include Log

  event :turn_started
  event :turn_ended

  def_delegators :@entities, :[], :size, :each

  attr_reader :entities, :map
  attr_accessor :player

  def friend?(faction); faction.is_a? self.class; end
  def enemy?(faction); not friend?(faction); end
  def to_s; Inflector.demodulize self.class.name; end
  def minimap_color; self.class::COLOR; end
  def active?; @active; end
  def inactive?; !@active; end

  def initialize(map)
    @map = map
    @entities = []
    @active = false
    @player = nil
  end

  def <<(entity)
    @entities << entity
  end

  def remove(entity)
    @entities.delete entity
  end

  # Start of first turn of the game.
  def start_game
    start_turn
  end

  # Restart from a loaded position.
  def resume_game
    @active = true
  end

  def start_turn
    log.info "#{self} started turn #{@map.turn + 1}"
    @active = true
    @entities.each(&:start_turn)

    publish :turn_started, @entities.dup
  end

  def end_turn
    @entities.each(&:end_turn)
    @map.end_turn
    @active = false

    publish :turn_ended
  end
end
