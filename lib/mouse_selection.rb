class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 25)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)
  
  def initialize(options = {})
    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @partial_move_image = Image["partial_move.png"]
    @final_move_image = Image["final_move.png"]
    @partial_move_too_far_image = Image["partial_move_too_far.png"]
    @final_move_too_far_image = Image["final_move_too_far.png"]

    @selected_tile = @hover_tile = nil

    @path = []

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)
  end
  
  def tile=(tile)
    @hover_tile = tile
  end

  def update
    super

    if @selected_tile
      if @hover_tile != @path.last
        @path = @selected_tile.objects.last.path_to(@hover_tile) || []
        @path.shift # Remove the starting square.
      end
    else
      @potential_moves.clear
    end
  end

  def calculate_potential_moves
    @potential_moves = @selected_tile.objects[0].potential_moves
  end
  
  def draw
    # Draw a disc under the selected object.
    if @selected_tile
      selected_color = Color::GREEN # Assume everyone is a friend for now.
      @selected_tile.draw_isometric_image @selected_image, ZOrder::TILE_SELECTION, color: selected_color

      # Highlight all pixels that character can travel to.
      pixel = $window.pixel
      @potential_moves.each do |tile|
        tile.draw_isometric_image pixel, ZOrder::TILE_SELECTION, color: MOVE_COLOR, mode: :additive
      end

      # Show path and end of the move-path chosen.
      if @hover_tile
        @path.each do |tile|
          can_move = @potential_moves.include? tile
          image = if tile == @path.last
            can_move ? @final_move_image : @final_move_too_far_image
          else
            can_move ? @partial_move_image : @partial_move_too_far_image
          end
          tile.draw_isometric_image image, ZOrder::TILE_SELECTION, color: color
        end
      end
    end
  end

  def left_click
    if @selected_tile
      # Move the character.
      if @potential_moves.include? @hover_tile
        character = @selected_tile.objects.last
        character.move_to @hover_tile
        @path.clear
        @selected_tile = @hover_tile
        calculate_potential_moves
      end
    elsif @hover_tile and @hover_tile.objects.any?
      # Select a character to move.
      @selected_tile = @hover_tile
      @potential_moves = @selected_tile.objects[0].potential_moves
    end
  end

  def right_click
    # Deselect the currently selected character.
    if @selected_tile
      @potential_moves.clear
      @path.clear
      @selected_tile = nil
    end
  end
end