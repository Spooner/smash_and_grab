# Abstract path class.
class Path
  extend Forwardable

  TILE_SIZE = 16

  def_delegators :@tiles, :[], :each, :first, :last, :size
  attr_reader :cost, :move_distance, :previous_path, :destination_distance, :tiles

  def initialize(previous_path, last, destination, extra_move_distance)
    @previous_path = previous_path
    @tiles = previous_path.tiles + [last]

    @move_distance = @previous_path.move_distance + extra_move_distance
    @destination_distance = @previous_path.destination_distance
    @cost = @move_distance + @destination_distance
  end

  def prepare_for_drawing(tiles_within_range)
    @@images ||= SpriteSheet.new("path.png", 32, 16, 4)

    @record = $window.record do
      if size > 1
        each.with_index do |tile, i|
          sheet_x, sheet_y =
              case tile
                when first
                  case tile.direction_to(self[i + 1])
                    when :up then [3, 0]
                    when :down then [0, 0]
                    when :left then [1, 0]
                    when :right then [2, 0]
                  end
                when last
                  case tile.direction_to(self[i - 1])
                    when :up then [3, 3]
                    when :down then [0, 3]
                    when :left then [2, 3]
                    when :right then [1, 3]
                  end
                else
                  case [tile.direction_to(self[i - 1]), tile.direction_to(self[i + 1])].sort
                    when [:down, :up] then [0, 1]
                    when [:left, :right] then [1, 1]
                    when [:left, :up] then [2, 2]
                    when [:down, :left] then [0, 2]
                    when [:right, :up] then [1, 2]
                    when [:down, :right] then [3, 2]
                    else
                      p tiles, tile, i, [tile.direction_to(self[i - 1]), tile.direction_to(self[i + 1])].sort.to_s
                      raise
                  end
          end

          color = if tile == first or tiles_within_range.include?(tile)
            Color::GREEN
          else
            Color::BLACK
          end

          @@images[sheet_x, sheet_y].draw_rot tile.x, tile.y, ZOrder::PATH, 0, 0.5, 0.5, 1, 1, color
        end
      end
    end
  end

  def draw(offset_x, offset_y, zoom)
    @record.draw offset_x, offset_y, ZOrder::PATH, zoom, zoom
  end
end

# A path consisting just of movement.
class MovePath < Path
  def initialize(previous_path, last, destination, extra_move_distance)
    super(previous_path, last, destination, last.cost + extra_move_distance)
  end
end

# A path consisting of melee, possibly with some movement beforehand.
class MeleePath < Path
  COLOR_IN_RANGE = Color::WHITE
  COLOR_OUT_OF_RANGE = Color.rgb(100, 100, 100)

  def attacker; self[-2]; end
  def defender; last; end
  def requires_movement?; previous_path.is_a? MovePath; end
  def initialize(previous_path, last, destination)
    super(previous_path, last, destination, 0)
  end

  def prepare_for_drawing(tiles_within_range)
    super(tiles_within_range)
    @draw_color = tiles_within_range.include?(last) ? COLOR_IN_RANGE : COLOR_OUT_OF_RANGE
  end

  def draw(*args)
    super(*args)

    if last.entity.is_a? Entity
      @@images[3, 1].draw_rot last.x, last.y, ZOrder::PATH, 0, 0.5, 0.5, 1, 1, @draw_color
    end
  end
end

class PathStart < Path
  def cost; 0; end
  def move_distance; 0; end

  def initialize(tile, destination)
    @tiles = [tile]
    @destination_distance = (last.grid_x - destination.grid_x).abs + (last.grid_y - destination.grid_y).abs
  end
end