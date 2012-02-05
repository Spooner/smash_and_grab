module SmashAndGrab
  module Gui
    class EntityPanel < Fidgit::Horizontal
      event :info_toggled

      def initialize(entity, info_shown, options = {})
        options = {
            padding: 0,
            spacing: 8,
        }.merge! options

        super options

        @entity = entity
        @info_shown = info_shown

        vertical padding: 0 do
          # TODO: Clicking on portrait should center.
          @portrait = image_frame @entity.image, padding: 0, background_color: Color::GRAY
          @info_toggle = toggle_button "Bio", value: @info_shown, tip: "Show/hide biography",
                                       font_height: 14, align_h: :center do |_, value|
            @info_shown = value
            publish :info_toggled, value
            switch_sub_panel
          end
        end

        vertical padding: 0, spacing: 4 do
          @name = label @entity.name
          @sub_panel_container = vertical spacing: 0, padding: 0
        end

        create_details_sub_panel
        create_info_sub_panel
        switch_sub_panel

        update_details @entity

        @entity.subscribe :changed, method(:update_details)
      end

      def switch_sub_panel
        @sub_panel_container.clear
        @sub_panel_container.add @info_shown ? @info_sub_panel : @details_sub_panel
      end

      def create_info_sub_panel
        @info_sub_panel = Fidgit::Vertical.new padding: 0, spacing: 0 do
          scroll_window width: 350, height: 72 do
            text_area text: "#{@entity.name} once ate a pomegranate, but it took all day and all night... " * 5,
                      background_color: Color::NONE, width: 330, font_height: 14
          end
        end
      end

      def create_details_sub_panel
        @details_sub_panel = Fidgit::Horizontal.new padding: 0, spacing: 0 do
          vertical padding: 0, spacing: 1, width: 160 do
            @health = label "", font_height: 20
            @movement_points = label "", font_height: 20
            @action_points = label "", font_height: 20
          end

          grid num_columns: 4, spacing: 4, padding: 0 do
            button_options = { font_height: 20, width: 28, height: 28, padding: 0, padding_left: 8 }

            @ability_buttons = {}

            label_options = button_options.merge border_thickness: 2, border_color: Color.rgba(255, 255, 255, 100)

            [:melee, :ranged, :sprint].each do |ability_name|
              if @entity.has_ability? ability_name
                ability = @entity.ability ability_name
                @ability_buttons[ability_name] = button("#{ability_name.to_s[0].upcase}#{ability.skill}",
                                                        button_options.merge(tip: ability.tip)) do

                  @entity.use_ability :sprint if ability_name == :sprint
                end
              else
                label "", label_options
              end
            end

            5.times do |i|
               label "", label_options
            end
          end
        end
      end

      def update_details(entity)
        @health.text = "HP: #{entity.health} / #{entity.max_health}"
        @movement_points.text = "MP: #{entity.mp} / #{entity.max_mp}"
        @action_points.text = "AP: #{entity.ap} / #{entity.max_ap}"

        if entity.has_ability? :sprint
          @movement_points.text += " +#{entity.ability(:sprint).movement_bonus}"
        end

        @ability_buttons.each do |ability, button|
          button.enabled = (entity.active? and (entity.has_ability?(ability) and entity.action_points >= entity.ability(ability).action_cost))
        end

        @portrait.image = entity.image
      end
    end
  end
end