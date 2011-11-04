class GameWindow < Chingu::Window
  attr_reader :pixel

  def setup
    enable_undocumented_retrofication

    @pixel = Image.create 1, 1
    @pixel.clear color: :white

    self.caption = "Smash and Grab - By Spooner [Escape - exit; Space - end turn; F5/F6 - quicksave/load; Ctrl-z/y - undo/redo; Arrows - scroll map]"

    self.cursor = true

    push_game_state MainMenu
  end
end