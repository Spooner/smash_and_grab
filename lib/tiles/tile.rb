class Tile < GameObject
  class Grass < Tile
    def passable?(character)
      false
    end
    def sprite; @@sprites[0]; end
  end
  
  class Concrete < Tile
    def sprite; @@sprites[1]; end
  end
  
  WIDTH, HEIGHT = 32, 16
  ADJACENT_POSITIONS = [[-1, 0], [0, -1], [1, 0], [0, 1]]
  #ADJACENT_POSITIONS = [[-1, 0], [0, -1], [1, 0], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]]
    
  attr_reader :objects, :grid_x, :grid_y
  def map; parent.map; end
  
  def initialize(grid_x, grid_y, options = {})
    @grid_x, @grid_y = grid_x, grid_y

    unless defined? @@sprites
      @@sprites = Image.load_tiles($window, File.expand_path("media/images/tiles.png", EXTRACT_PATH), 16, 16, true)
    end
    options[:image] = sprite
    options[:x] = (@grid_y + @grid_x) * WIDTH / 2
    options[:y] = (@grid_y - @grid_x) * HEIGHT / 2
    options[:rotation_center] = :center_center
    options[:zorder] = options[:y]

    @objects = []

    super(options)
  end

  def passable?(character)
    @objects.empty?
  end

  # List of squares directly adjacent to the character that are potentially passable.
  def adjacent_passable(character)
    tiles = ADJACENT_POSITIONS.map do |offset_x, offset_y|
      map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
    end

    tiles.compact!

    tiles.select! {|tile| tile.passable?(character) }

    tiles
  end

  def add_object(object)
    raise "can't re-add object" if @objects.include? object

    @objects << object
    object.x, object.y = [x, y]
  end
  
  def draw
    color = Color::WHITE
    @image.draw_as_quad x - WIDTH / 2, y,  color, # Left
                        x, y - HEIGHT / 2, color, # Top
                        x + WIDTH / 2, y,  color, # Right
                        x, y + HEIGHT / 2, color, # Bottom
                        zorder
  end
end