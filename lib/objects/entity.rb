require 'set'

class Entity < StaticObject
  class Character < Entity; end

  # Abstract path class.
  class Path
    TILE_SIZE = 16
    attr_reader :cost, :move_distance, :current, :first, :previous_path, :destination_distance

    def tiles; @previous_path.tiles + [current]; end

    def initialize(previous_path, current, destination, extra_move_distance)
      @previous_path, @current = previous_path, current

      @move_distance = @previous_path.move_distance + extra_move_distance
      @first = @previous_path.first
      @destination_distance = @previous_path.destination_distance
      @cost = @move_distance + @destination_distance
    end
  end

  # A path consisting just of movement.
  class MovePath < Path
    def initialize(previous_path, current, destination, extra_move_distance)
      super(previous_path, current, destination, current.cost + extra_move_distance)
    end
  end

  # A path consisting of melee, possibly with some movement beforehand.
  class MeleePath < Path
    def attacker; @previous_path.current; end
    def defender; @current; end
    def requires_movement?; previous_path.is_a? MovePath; end

    def initialize(previous_path, current, destination)
      super(previous_path, current, destination, MELEE_COST)
    end
  end

  class PathStart < Path
    attr_reader :tiles

    def cost; 0; end
    def move_distance; 0; end

    def initialize(tile, destination)
      @current = tile
      @tiles = [tile]
      @destination_distance = (@current.grid_x - destination.grid_x).abs + (@current.grid_y - destination.grid_y).abs
    end
  end

  DATA_TYPE = 'type'
  DATA_IMAGE_INDEX = 'image_index'
  DATA_TILE = 'tile'
  DATA_MOVEMENT_POINTS = 'movement_points'
  DATA_FACING = 'facing'
  MOVEMENT_POINTS_PER_TURN = 5
  MELEE_COST = 2

  attr_reader :faction, :movement_points

  def to_s; "<#{self.class.name} [#{tile.grid_x}, #{tile.grid_y}]>"; end

  def initialize(map, data)
    @map = map

    unless defined? @@sprites
      @@sprites = SpriteSheet.new("characters.png", 64 + 2, 64 + 2)
    end

    @image_index = data[DATA_IMAGE_INDEX]

    options = {
        image: @@sprites.each.to_a[@image_index],
        factor_x: data[DATA_FACING] == 'right' ? 1 : -1,
    }

    super(@map.tile_at_grid(*data[DATA_TILE]), options)

    # TODO: Obviously, this is dumb way to do factions.
    # Get a hash of the image, so we can compare it.
    @faction = @image.hash

    @movement_points = data[DATA_MOVEMENT_POINTS] || MOVEMENT_POINTS_PER_TURN

    @map << self
  end

  def melee(other)
    # TODO: Resolve melee!
    p [:melee, self, other]
    @movement_points -= MELEE_COST
  end

  def turn_reset
    @movement_points = MOVEMENT_POINTS_PER_TURN
  end

  def friend?(character)
    # TODO: Make this faction-based or something.
    @faction == character.faction
  end

  def enemy?(character); not friend?(character); end

  def move?; @movement_points > 0; end
  def end_turn_on?(person); false; end
  def impassable?(character); enemy? character; end
  def passable?(character); friend? character; end

  def potential_moves(options = {})
    options = {
        starting_tile: tile,
        tiles: Set.new,
    }.merge! options

    starting_tile = options[:starting_tile]
    tiles = options[:tiles]

    starting_tile.exits(self).each do |wall|

      tile = wall.destination(starting_tile, self)
      unless tiles.include? tile
        path = path_to(tile)

        if path and @movement_points >= path.move_distance
          # Can move onto this square - calculate further paths if we can move through the square.
          tiles << tile
          if path.is_a?(MovePath) and @movement_points > path.move_distance
            potential_moves(starting_tile: tile, tiles: tiles)
          end
        end
      end
    end

    tiles
  end

  # A* path-finding.
  def path_to(destination_tile)
    return nil unless destination_tile.passable? self
    return nil if destination_tile == tile

    closed_tiles = Set.new # Tiles we've already dealt with.
    open_paths = { tile => PathStart.new(tile, destination_tile) } # Paths to check { tile => path_to_tile }.

    while open_paths.any?
      # Check the (expected) shortest path and move it to closed, since we have considered it.
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.current

      open_paths.delete current_tile
      closed_tiles << current_tile

      # Check adjacent tiles.
      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile, self) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile, self)

        new_path = if entity = testing_tile.objects.last and enemy?(entity)
          MeleePath.new(path, testing_tile, destination_tile)
        elsif testing_tile.passable?(self)
          MovePath.new(path, testing_tile, destination_tile, wall.movement_cost(self))
        else
          nil
        end

        return new_path if new_path.nil? or testing_tile == destination_tile

        # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
        if old_path = open_paths[testing_tile]
          if new_path.move_distance < old_path.move_distance
            open_paths.delete old_path
            open_paths[testing_tile] = new_path
          end
        else
          open_paths[testing_tile] = new_path
        end
      end
    end

    nil # Failed to connect at all.
  end

  def move(tiles, movement_cost)
    raise "Not enough movement points (tried to move #{movement_cost} with #{@movement_points} left)" unless movement_cost <= @movement_points

    parent.mouse_selection.select nil

    destination = tiles.last
    @movement_points -= movement_cost

    change_in_x = destination.x - @tile.x

    # Turn based on movement.
    unless change_in_x == 0
      self.factor_x = change_in_x > 0 ? 1 : -1
    end

    @tile.remove_object self
    destination.add_object self

    [@tile, destination].each {|t| parent.minimap.update_tile t }

    @tile = destination

    parent.mouse_selection.select self
  end

  def minimap_color
    # TODO: Friend blue, enemy red.
    :red
  end

  def to_json(*a)
    {
        DATA_TYPE => Inflector.demodulize(self.class.name),
        DATA_IMAGE_INDEX => @image_index,
        DATA_TILE => [tile.grid_x, tile.grid_y],
        DATA_MOVEMENT_POINTS => @movement_points,
        DATA_FACING => factor_x > 0 ? :right : :left,
    }.to_json(*a)
  end
end