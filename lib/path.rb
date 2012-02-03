module SmashAndGrab
module Paths
# Abstract path class.
class Path
  extend Forwardable

  TILE_SIZE = 16

  attr_reader :cost, :move_distance, :previous_path, :destination_distance, :first, :last

  def accessible?; true; end
  def tiles; @previous_path.tiles + [@last]; end
  def self.sprites; @@sprites ||= SpriteSheet.new("path.png", 32, 16, 4); end
  def sprites; self.class.sprites; end

  def initialize(previous_path, next_tile, extra_move_distance)
    @previous_path = previous_path
    @first, @last = @previous_path.first, next_tile

    @move_distance = @previous_path.move_distance + extra_move_distance
    @destination_distance = @previous_path.destination_distance
    @cost = @move_distance + @destination_distance
  end

  def prepare_for_drawing(tiles_within_range)
    path_tiles = tiles

    @record = $window.record(1, 1) do
      tiles.each_with_index do |tile, i|
        sheet_x, sheet_y =
            case tile
              when @first
                case tile.direction_to(path_tiles[i + 1])
                  when :up then [3, 0]
                  when :down then [0, 0]
                  when :left then [1, 0]
                  when :right then [2, 0]
                  else raise
                end
              when @last
                case tile.direction_to(path_tiles[i - 1])
                  when :up then [3, 3]
                  when :down then [0, 3]
                  when :left then [2, 3]
                  when :right then [1, 3]
                  else raise
                end
              else
                case [tile.direction_to(path_tiles[i - 1]), tile.direction_to(path_tiles[i + 1])].sort
                  when [:down, :up] then [0, 1]
                  when [:left, :right] then [1, 1]
                  when [:left, :up] then [2, 2]
                  when [:down, :left] then [0, 2]
                  when [:right, :up] then [1, 2]
                  when [:down, :right] then [3, 2]
                  else raise
                end
            end

        color = if tile == first or tiles_within_range.include?(tile)
          Color::GREEN
        else
          Color::BLACK
        end

        sprites[sheet_x, sheet_y].draw_rot tile.x, tile.y, ZOrder::PATH, 0, 0.5, 0.5, 1, 1, color
      end
    end
  end

  def draw
    @record.draw 0, 0, ZOrder::PATH
  end
end

# A path consisting just of movement.
class Move < Path
  def mover; first.object; end
  def initialize(previous_path, last, extra_move_distance)
    super(previous_path, last, last.movement_cost + extra_move_distance)
  end
end

# A path consisting of melee, possibly with some movement beforehand.
class Melee < Path
  COLOR_IN_RANGE = Color::WHITE
  COLOR_OUT_OF_RANGE = Color.rgb(100, 100, 100)

  def attacker; previous_path.last.object; end
  def defender; last.object; end
  def requires_movement?; previous_path.is_a? Paths::Move; end
  def initialize(previous_path, last)
    super(previous_path, last, 0)
  end

  def prepare_for_drawing(tiles_within_range)
    super(tiles_within_range)
    @draw_color = tiles_within_range.include?(last) ? COLOR_IN_RANGE : COLOR_OUT_OF_RANGE
  end

  def draw(*args)
    super(*args)

    if last.object.is_a? Objects::Entity
      sprites[3, 1].draw_rot last.x, last.y, ZOrder::PATH, 0, 0.5, 0.5, 1, 1, @draw_color
    end
  end
end

# First path in chain, others will be MovePath or MeleePath
class Start < Path
  def tiles; [@last]; end
  def cost; 0; end
  def move_distance; 0; end

  def initialize(origin, destination)
    @last = @first = origin
    @destination_distance = (origin.grid_x - destination.grid_x).abs + (origin.grid_y - destination.grid_y).abs
  end
end

# Path where the destination is unreachable.
class Inaccessible < Path
  def accessible?; false; end
  def tiles; [@last]; end

  def initialize(destination)
    @last = destination
  end

  def draw(*args)
    sprites[2, 1].draw_rot last.x, last.y, ZOrder::PATH, 0, 0.5, 0.5
  end

  def prepare_for_drawing(tiles_within_range); end
end

# Path going to the same location as it started.
class None < Path
  def accessible?; false; end
  def tiles; []; end
  def initialize; end
  def prepare_for_drawing(tiles_within_range); end
  def draw(*args); end
end
end
end