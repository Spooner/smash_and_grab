require_relative 'world'

class PlayLevel < World
  SAVE_FOLDER = File.expand_path("saves", ROOT_PATH)
  LOAD_FOLDER = File.expand_path("config/levels", EXTRACT_PATH)
  QUICKSAVE_FILE = File.expand_path("quicksave.sgs", SAVE_FOLDER)
  AUTOSAVE_FILE = File.expand_path("autosave.sgs", SAVE_FOLDER)
  ORIGINAL_FILE = File.expand_path("01_bank.sgl", LOAD_FOLDER)

  def initialize
    super()

    add_inputs(space: :end_turn)

    @players = [Player::Human.new, Player::AI.new, Player::AI.new]

    load_game ORIGINAL_FILE

    @players.each.with_index do |player, i|
      map.factions[i].player = player
      player.faction = map.factions[i]
    end

    save_game AUTOSAVE_FILE

    @mouse_selection = MouseSelection.new @map
  end

  def create_gui
    # Unit roster.
    @container = Fidgit::Container.new do |container|
      @minimap = Minimap.new parent: container

      @summary_bar = vertical parent: container, padding: 1, spacing: 1, background_color: Color::BLACK do |packer|
        [@map.baddies.size, 8].min.times do |i|
          baddy = @map.baddies[i]
          summary = Fidgit::EntitySummary.new baddy, parent: packer
          summary.subscribe :left_mouse_button do
            @mouse_selection.select baddy if baddy.alive?
            @info_panel.entity = baddy
          end
        end
      end

      # Info panel.
      @info_panel = InfoPanel.new parent: container

      # Button box.
      @button_box = vertical parent: container, padding: 1, spacing: 2, background_color: Color::BLACK do
        @turn_label = label " ", font_height: 3.5, padding_left: 1

        horizontal padding: 0 do
          button "Undo", padding_h: 1, font_height: 5 do
            undo_action
          end

          button "Redo", padding_h: 1, font_height: 5, align_h: :right do
            redo_action
          end
        end

        button "End turn" do
          end_turn
        end
      end

      @button_box.x, @button_box.y = $window.width / 4 - @button_box.width, $window.height / 4 - @button_box.height
    end
  end

  def end_turn
    @mouse_selection.select nil
    @map.active_faction.end_turn
    save_game AUTOSAVE_FILE
  end

  def undo_action
    selection = @mouse_selection.selected
    @mouse_selection.select nil
    @map.actions.undo if @map.actions.can_undo?
    @mouse_selection.select selection if selection
  end

  def redo_action
    selection = @mouse_selection.selected
    @mouse_selection.select nil
    @map.actions.redo if @map.actions.can_redo?
    @mouse_selection.select selection if selection
  end

  def quicksave
    save_game QUICKSAVE_FILE
  end

  def quickload
    load_game QUICKSAVE_FILE
  end

  def map=(map)
    super(map)

    @mouse_selection = MouseSelection.new @map

    map
  end

  def draw
    super

    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        @mouse_selection.draw @camera_offset_x, @camera_offset_y, @zoom
        @map.draw_grid @camera_offset_x, @camera_offset_y, @zoom if holding? :g
      end
    end
  end

  def update
    super

    @mouse_selection.tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height and
                                @container.each.none? {|e| e.hit? $window.mouse_x / 4, $window.mouse_y / 4 }

      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    @mouse_selection.update

    @map.active_faction.player.update

    @turn_label.text = "Turn: #{@map.turn + 1} (#{@map.active_faction})"
  end
end
