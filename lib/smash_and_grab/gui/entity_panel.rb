# - encoding: utf-8 -

module SmashAndGrab
  module Gui
    class EntityPanel < Fidgit::Horizontal
      TITLE_COLOR = Color.rgb(150, 150, 150)

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
                                       font_height: FontHeight::SMALL, align_h: :center do |_, value|
            @info_shown = value
            publish :info_toggled, value
            switch_sub_panel
          end
        end

        vertical padding: 0, spacing: 1.5 do
          @name = label @entity.name, font_height: FontHeight::LARGE, color: Color::WHITE
          label TITLE_COLOR.colorize("#{entity.title} - #{@entity.faction.colorized_name}"), font_height: 12
          @sub_panel_container = vertical spacing: 0, padding: 0
        end

        create_details_sub_panel
        create_info_sub_panel
        switch_sub_panel

        update_details @entity

        @changed_event = @entity.subscribe :changed, method(:update_details)
      end

      def finalize
        @changed_event.unsubscribe
      end

      def switch_sub_panel
        @sub_panel_container.clear
        @sub_panel_container.add @info_shown ? @info_sub_panel : @details_sub_panel
      end

      def create_info_sub_panel
        @info_sub_panel = Fidgit::Vertical.new padding: 0, spacing: 0 do
          text = nil
          scroll = scroll_window width: 350, height: 68 do
            text = text_area text: "#{@entity.name} once ate a pomegranate, but it took all day and all night... " * 5,
                                  width: 330, font_height: FontHeight::SMALL, editable: false
          end
          scroll.background_color = text.background_color
        end
      end

      def create_details_sub_panel
        @details_sub_panel = Fidgit::Horizontal.new padding: 0, spacing: 0 do
          vertical padding: 0, spacing: 1, width: 160 do
            @health = label "", font_height: FontHeight::SMALL
            @movement_points = label "", font_height: FontHeight::SMALL
            @energy_points = label "", font_height: FontHeight::SMALL
            @action_points = label "", font_height: FontHeight::SMALL
            @resistances = label "", font_height: FontHeight::MEDIUM
          end

          grid num_columns: 4, spacing: 4, padding: 0 do
            button_options = { font_height: FontHeight::LARGE, width: 28, height: 28, padding: 0, padding_left: 8 }

            @ability_buttons = {}

            label_options = button_options.merge border_thickness: 2, border_color: Color.rgba(255, 255, 255, 100)

            extra_skills = []
            # First four are always arranged on the top row in static positions.
            # Any others are just arranged in the second row.
            [:melee, :ranged, :sprint, :drop, :flurry, :second_wind].each.with_index do |ability_name, i|
              if @entity.has_ability? ability_name
                extra_skills << ability_name if i >= 4

                ability = @entity.ability ability_name
                @ability_buttons[ability_name] = button("#{ability_name.to_s[0].upcase}#{ability.skill}",
                                                        button_options.merge(tip: ability.tip)) do

                  unless [:melee, :ranged].include? ability_name
                    @entity.use_ability ability_name
                  end
                end
              else
                label "", label_options if i < 4
              end
            end

            (4 - extra_skills.size).times do |i|
               label "", label_options
            end
          end
        end
      end

      def update_details(entity)
        return unless entity.faction.player

        @health.text = "HP: #{entity.hp} / #{entity.max_hp}"
        @movement_points.text = "MP: #{entity.mp} / #{entity.max_mp}"
        @action_points.text = "AP: #{entity.ap} / #{entity.max_ap}"
        @energy_points.text = "EP: #{entity.ep} / #{entity.max_ep}"
        @resistances.text = entity.resistances_and_vulnerabilities_string

        if entity.has_ability? :sprint
          @movement_points.text += " + #{entity.ability(:sprint).movement_bonus}"
        end

        @ability_buttons.each do |ability, button|
          button.enabled = entity.active? && entity.faction.player.human? && entity.use_ability?(ability)

          # TODO: this should be more sensible (allows un-sprinting).
          if ability == :sprint && entity.active? && entity.faction.player.human? && entity.ability(ability).deactivate?
            button.enabled = true
          end
        end

        @portrait.image = entity.image
      end
    end
  end
end