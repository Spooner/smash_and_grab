require_relative 'action_history'

class GameActionHistory < ActionHistory
  def create_action(type, *args); GameAction.const_get(Inflector.camelize(type)).new @map, *args; end

  def initialize(map, data)
    @map = map

    super(Float::INFINITY)

    if data
      @actions = data.map do |action_data|
        GameAction.const_get(action_data[GameAction::DATA_TYPE]).new map, action_data
      end

      @last_done = @actions.size - 1
    end
  end
end


class GameAction < Fidgit::History::Action
  include Log

  class Melee < self
    DATA_ATTACKER = 'attacker'
    DATA_DEFENDER = 'defender'

    def initialize(map, data)
      @map = map

      case data
        when MeleePath
          @attacker, @defender = data.attacker, data.defender
          @time = Time.now
        when Hash
          @attacker = @map.tile_at_grid(*data[DATA_ATTACKER])
          @defender = @map.tile_at_grid(*data[DATA_DEFENDER])
          @time = data[DATA_TIME]
        else
          raise data.to_s
      end
    end

    def do
      @attacker.entity.melee(@defender.entity)
    end

    def can_be_undone?; false; end

    def save_data
      {
        DATA_ATTACKER => @attacker.grid_position,
        DATA_DEFENDER => @defender.grid_position,
      }
    end
  end

  class Move < self
    DATA_PATH = 'path'
    DATA_MOVEMENT_COST = 'movement_cost'

    def initialize(map, data)
      @map = map

      case data
        when MovePath
          @path = data.tiles
          @movement_cost = data.move_distance
          @time = Time.now
        when Hash
          @path = data[DATA_PATH].map {|x, y| @map.tile_at_grid(x, y) }
          @movement_cost = data[DATA_MOVEMENT_COST]
          @time = data[DATA_TIME]
        else
          raise data.to_s
      end
    end

    def do
      object = @path.first.objects.last
      object.move(@path[1..-1], @movement_cost)
    end

    def undo
      object = @path.last.objects.last
      object.move(@path.reverse[1..-1], -@movement_cost)
    end

    def save_data
      {
        DATA_PATH => @path.map(&:grid_position),
        DATA_MOVEMENT_COST => @movement_cost,
      }
    end
  end

  class EndTurn < self
    def initialize(map, data = nil)
      @map = map
      super
    end

    def can_be_undone?; false; end

    def do
    end
  end

  DATA_TYPE = 'type'
  DATA_TIME = 'timestamp'

  def can_be_undone?; true; end

  def to_json(*a)
    {
      DATA_TYPE => Inflector.demodulize(self.class.name),
      DATA_TIME => @time,
    }.merge(save_data).to_json(*a)
  end

  def save_data
    {
    }
  end
end