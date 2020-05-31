module SDC
	class Launshi

		COLOR_TEXT_REGULAR = SDC::Color.new(255, 255, 255, 255)
		COLOR_TEXT_DISABLED = SDC::Color.new(127, 0, 0, 255)
		COLOR_TEXT_INPUT = SDC::Color.new(0, 0, 0, 255)

		FILTER_NAME = 0
		FILTER_DESC = 1

		class SceneLaunshi < SDC::Scene

			def at_init
				@launshi = SDC::Launshi.new
				@launshi.load_configs("demo_projects")
				@launshi.load_configs("projects", create_if_missing: true)

				SDC::Data.load_font(:Standard, filename: "assets/fonts/arial.ttf")
				@title_size = 20
				@wrong_version_size = 15
				@title_offset_x = 5
				@title_offset_y = 5

				@launshi.apply_filters

				@active_config_id = 0

				@start_buttons = []
				@info_buttons = []
				@genre_buttons = []

				@info_window = nil

				name_button_filter_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(5, 13 + 1*(@title_offset_y + @title_size)), SDC::Coordinates.new(300, 20))
				@name_filter_button = SDC::Button.new(shape: name_button_filter_shape)

				name_finish_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(5 + 300, 13 + 1*(@title_offset_y + @title_size)), SDC::Coordinates.new(30, 30))
				@name_finish_button = SDC::Button.new(shape: name_finish_shape)

				desc_button_filter_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(5, 13 + 3*(@title_offset_y + @title_size)), SDC::Coordinates.new(300, 20))
				@desc_filter_button = SDC::Button.new(shape: desc_button_filter_shape)

				desc_finish_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(5 + 300, 13 + 3*(@title_offset_y + @title_size)), SDC::Coordinates.new(30, 30))
				@desc_finish_button = SDC::Button.new(shape: desc_finish_shape)

				0.upto(3) do |i|
					button_start_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(585, i*180 + 140), SDC::Coordinates.new(80, 30))
					button_start = SDC::Button.new(shape: button_start_shape)
					@start_buttons[i] = button_start

					button_info_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(585 + 100, i*180 + 140), SDC::Coordinates.new(80, 30))
					button_info = SDC::Button.new(shape: button_info_shape)
					@info_buttons[i] = button_info
				end

				offset_y = 10 + 5*(@title_offset_y + @title_size) + 5
				gx = 0
				gy = 0
				SDC::Launshi::AVAILABLE_GENRES.each do |genre|
					button_genre_shape = SDC::CollisionShapeBox.new(SDC::Coordinates.new(10 + 180*gx, offset_y + (30 + 10)*gy), SDC::Coordinates.new(30, 30))
					button_genre = SDC::Button.new(shape: button_genre_shape)
					@genre_buttons.push(button_genre)

					gx += 1
					if gx == 2 then
						gx = 0
						gy += 1
					end
				end
			end
			
			def scroll_down
				@active_config_id += 1
				@active_config_id = [@active_config_id, [0, @launshi.get_configs.size - 4 - 1].max].min
			end

			def scroll_up
				@active_config_id -= 1
				@active_config_id = [@active_config_id, 0].max
			end

			def at_exit
				SDC.text_input = nil
			end

			def handle_event(event)
				if event.has_type?(:Closed) then
					SDC::Launshi::set_definite_exit
					SDC.next_scene = nil

				elsif SDC.text_input == FILTER_NAME then
					SDC.process_text_input(event: event, text_buffer: @launshi.name_filter) do |char, text|
						if char == C_NEWLINE || char == C_CAR_RET then
							SDC.text_input = nil
							break
						end
					end
					@launshi.apply_filters

				elsif SDC.text_input == FILTER_DESC then
					SDC.process_text_input(event: event, text_buffer: @launshi.description_filter) do |char, text|
						if char == C_NEWLINE || char == C_CAR_RET then
							SDC.text_input = nil
							break
						end
					end
					@launshi.apply_filters

				elsif event.has_type?(:KeyPressed) then
					if event.key_pressed?(:Down) then
						scroll_down
					elsif event.key_pressed?(:Up) then
						scroll_up
					elsif event.key_pressed?(:Escape) && @info_window then
						@info_window = nil
					end

				end

				if @info_window then
					if event.has_type?(:MouseButtonReleased) then
						if !SDC.mouse_touching?(SDC::CollisionShapeBox.new(SDC.xy(240, 60), SDC.xy(800, 600))) then
							@info_window = false
						end
					end

				else
					if event.has_type?(:MouseWheelScrolled) then
						if event.mouse_scrolled_up? then
							scroll_up
						elsif event.mouse_scrolled_down? then
							scroll_down
						end

					elsif event.has_type?(:MouseButtonReleased) then
						if event.mouse_left_click? then
							project_start_id = nil
							project_info_id = nil

							@name_filter_button.on_mouse_touch do
								SDC.text_input = FILTER_NAME
							end

							@name_finish_button.on_mouse_touch do
								SDC.text_input = nil
							end

							@desc_filter_button.on_mouse_touch do
								SDC.text_input = FILTER_DESC
							end

							@desc_finish_button.on_mouse_touch do
								SDC.text_input = nil
							end

							0.upto(3) do |i|

								configs = @launshi.get_filtered_configs
								config = configs[@active_config_id + i]

								if config && @launshi.check_version(config) then
									@start_buttons[i].on_mouse_touch do
										project_start_id = @active_config_id + i
									end
								end

								@info_buttons[i].on_mouse_touch do
									project_info_id = @active_config_id + i
								end
							end

							if project_start_id && project_start_id < @launshi.get_filtered_configs.size then
								SDC::Launshi.set_final_config(project_start_id, @launshi)
								SDC.next_scene = nil

							elsif project_info_id && project_info_id < @launshi.get_filtered_configs.size then
								@info_window = project_info_id if @launshi.check_version(@launshi.get_filtered_configs[project_info_id])
							end

							0.upto(SDC::Launshi::AVAILABLE_GENRES.size - 1) do |i|
								@genre_buttons[i].on_mouse_touch do	
									@launshi.genre_filters[i] = !@launshi.genre_filters[i]
									@launshi.apply_filters
								end
							end

						end
					end

				end
			end

			def update
				
			end

			def draw_short_info(config, index, offset_x, offset_y, z, draw_buttons: true)
				# TODO: More sophisticated length checks

				genre_list = "Genres: " + config.json["genres"][0..4].join(", ") + (config.json["genres"].size > 5 ? ", ..." : "")
				dev_list = "Developers: " + config.json["developers"][0..4].join(", ") + (config.json["developers"].size > 5 ? ", ..." : "") + " (" + config.json["year"].to_s + ")"

				offset = SDC.xy(offset_x + @title_offset_x, offset_y + @title_offset_y)

				SDC.draw_text(index: "TextTitle#{index}".to_sym, text: config.json["title"], font_index: :Standard, size: @title_size, coordinates: offset, z: z)

				offset.y += @title_size + @title_offset_y
				SDC.draw_text(index: "TextSubtitle#{index}".to_sym, text: config.json["subtitle"], font_index: :Standard, size: @title_size, coordinates: offset, z: z)

				offset.y += @title_size + @title_offset_y
				SDC.draw_text(index: "TextVersion#{index}".to_sym, text: "Project version: " + config.json["project_version"], font_index: :Standard, size: @title_size, coordinates: offset, z: z)

				offset.y += @title_size + @title_offset_y
				SDC.draw_text(index: "TextGenres#{index}".to_sym, text: genre_list, font_index: :Standard, size: @title_size, coordinates: offset, z: z)

				offset.y += @title_size + @title_offset_y
				SDC.draw_text(index: "TextDevs#{index}".to_sym, text: dev_list, font_index: :Standard, size: @title_size, coordinates: offset, z: z)

				# TODO: Use actual button drawing to simplify this

				if draw_buttons
					version = config.json["shidacea_version"]
				
					correct_version = @launshi.check_version(config)
					text_color = (correct_version ? COLOR_TEXT_REGULAR : COLOR_TEXT_DISABLED)

					SDC.draw_texture(filename: "assets/graphics/Button.png", coordinates: SDC.xy(offset_x + @title_offset_x, offset_y + 140), z: z)
					SDC.draw_text(index: "TextStart#{index}".to_sym, text: "START", font_index: :Standard, size: @title_size, color: text_color, coordinates: SDC.xy(offset_x + @title_offset_x + 8, offset_y + 140 + 2), z: z)
	
					SDC.draw_texture(filename: "assets/graphics/Button.png", coordinates: SDC.xy(offset_x + @title_offset_x + 100, offset_y + 140))
					SDC.draw_text(index: "TextInfo#{index}".to_sym, text: "INFO", font_index: :Standard, size: @title_size, color: text_color, coordinates: SDC.xy(offset_x + @title_offset_x + 100 + 15, offset_y + 140 + 2), z: z)
				
					if correct_version == false then
						SDC.draw_text(index: "TextErrorTop1#{index}".to_sym, text: "Project does not run on Shidacea version #{SDC::Script.version}", font_index: :Standard, size: @wrong_version_size, color: COLOR_TEXT_DISABLED, coordinates: SDC.xy(offset_x + @title_offset_x + 200 - 10, offset_y + 140 - 3), z: z)
						SDC.draw_text(index: "TextErrorTop2#{index}".to_sym, text: "Required Shidacea version is at least #{config.json['shidacea_version'].split('.')[0..1].join('.')}", font_index: :Standard, size: @wrong_version_size, color: COLOR_TEXT_DISABLED, coordinates: SDC.xy(offset_x + @title_offset_x + 200 - 10, offset_y + 140 - 3 + @wrong_version_size), z: z)
					elsif correct_version == nil then
						SDC.draw_text(index: "TextErrorTop1#{index}".to_sym, text: "Project does not run on Shidacea version #{SDC::Script.version}", font_index: :Standard, size: @wrong_version_size, color: COLOR_TEXT_DISABLED, coordinates: SDC.xy(offset_x + @title_offset_x + 200 - 10, offset_y + 140 - 3), z: z)
						SDC.draw_text(index: "TextErrorTop2#{index}".to_sym, text: "Required Shidacea version is outdated version #{config.json['shidacea_version'].split('.')[0..1].join('.')}", font_index: :Standard, size: @wrong_version_size, color: COLOR_TEXT_DISABLED, coordinates: SDC.xy(offset_x + @title_offset_x + 200 - 10, offset_y + 140 - 3 + @wrong_version_size), z: z)
					end
				end
				
			end

			def draw
				view_default = SDC::View.new(SDC::FloatRect.new(0, 0, 1280, 720))
				SDC.window.set_view(view_default)

				SDC.draw_texture(filename: "assets/graphics/FrameFilters.png", coordinates: SDC.xy(0, 0))

				SDC.draw_text(index: :TitleFilter, text: "Title filter", font_index: :Standard, size: @title_size, coordinates: SDC.xy(10, 10))

				if SDC.text_input == FILTER_NAME then
					SDC.draw_texture(filename: "assets/graphics/InputSelected.png", coordinates: SDC.xy(5, 13 + 1*(@title_offset_y + @title_size)))
					SDC.draw_texture(filename: "assets/graphics/Finish.png", coordinates: SDC.xy(5 + 300, 13 - 5 + 1*(@title_offset_y + @title_size)))
				else
					SDC.draw_texture(filename: "assets/graphics/Input.png", coordinates: SDC.xy(5, 13 + 1*(@title_offset_y + @title_size)))
				end

				# TODO: Better cap for text fields, maybe using dedicated SDC routines and sf::Font::getGlyph
				SDC.draw_text(index: :TitleFilterInput, text: @launshi.name_filter[0..17], font_index: :Standard, size: @title_size, color: COLOR_TEXT_INPUT, coordinates: SDC.xy(10, 10 + 1*(@title_offset_y + @title_size)))

				SDC.draw_text(index: :DescFilter, text: "Description filter", font_index: :Standard, size: @title_size, coordinates: SDC.xy(10, 10 + 2*(@title_offset_y + @title_size)))

				if SDC.text_input == FILTER_DESC then
					SDC.draw_texture(filename: "assets/graphics/InputSelected.png", coordinates: SDC.xy(5, 13 + 3*(@title_offset_y + @title_size)))
					SDC.draw_texture(filename: "assets/graphics/Finish.png", coordinates: SDC.xy(5 + 300, 13 - 5 + 3*(@title_offset_y + @title_size)))
				else
					SDC.draw_texture(filename: "assets/graphics/Input.png", coordinates: SDC.xy(5, 13 + 3*(@title_offset_y + @title_size)))
				end
				
				SDC.draw_text(index: :DescFilterInput, text: @launshi.description_filter[0..17], font_index: :Standard, size: @title_size, color: COLOR_TEXT_INPUT, coordinates: SDC.xy(10, 10 + 3*(@title_offset_y + @title_size)))

				SDC.draw_text(index: :GenreFilter, text: "Genre filter", font_index: :Standard, size: @title_size, coordinates: SDC.xy(10, 10 + 4*(@title_offset_y + @title_size)))
				
				offset_y = 10 + 5*(@title_offset_y + @title_size) + 5
				gx = 0
				gy = 0
				0.upto(SDC::Launshi::AVAILABLE_GENRES.size - 1) do |i|
					genre = SDC::Launshi::AVAILABLE_GENRES[i]
					if @launshi.genre_filters[i] then
						SDC.draw_texture(filename: "assets/graphics/Checkbox_ticked.png", coordinates: SDC.xy(10 + 180*gx, offset_y + (30 + 10)*gy))
					else
						SDC.draw_texture(filename: "assets/graphics/Checkbox.png", coordinates: SDC.xy(10 + 180*gx, offset_y + (30 + 10)*gy))
					end

					SDC.draw_text(index: "GenreText#{gx}_#{gy}".to_sym, text: genre, font_index: :Standard, size: @title_size, coordinates: SDC.xy(10 + 30 + 10 + 180*gx, offset_y + 2 + (30 + 10)*gy))
					@genre_buttons[gy*2 + gx].draw
					
					gx += 1
					if gx == 2 then
						gx = 0
						gy += 1
					end
				end

				configs = @launshi.get_filtered_configs
				0.upto(3) do |i|
					config = configs[@active_config_id + i]
					next if !config

					SDC.draw_texture(filename: "assets/graphics/FrameGame.png", coordinates: SDC.xy(400, i*180))
					SDC.draw_texture(index: config.path.to_sym, coordinates: SDC.xy(426, i*180 + 26)) if config.json["thumbnail"] && !config.json["thumbnail"].empty?

					draw_short_info(config, i, 580, i*180, 0)
				end

				SDC.draw_texture(filename: "assets/graphics/FrameScroll.png", coordinates: SDC.xy(1240, 0))

				if @info_window then
					# TODO: Include shade over main window
					config = configs[@info_window]

					SDC.draw_texture(filename: "assets/graphics/Info.png", coordinates: SDC.xy(240, 60), z: 1)
					SDC.draw_texture(index: config.path.to_sym, coordinates: SDC.xy(240 + 5, 60 + 5), z: 1) if config.json["thumbnail"] && !config.json["thumbnail"].empty?

					draw_short_info(config, "INFO", 240 + 128 + 10, 60, 1, draw_buttons: false)
					SDC.draw_text(index: :InfoDescription, text: config.json["description"].split("\n")[0..4].join("\n"), font_index: :Standard, size: @title_size, coordinates: SDC.xy(240 + 10, 60 + 128 + 10), z: 1)
					
					# Preliminary screenshot drawing

					i = 0
					config.json["screenshots"]&.each do |screenshot|
						next if i > 0
						texture_size = SDC::Data.textures["#{config.path}_#{i}".to_sym].size

						view_preview = SDC::View.new(SDC::FloatRect.new(0, 0, texture_size.x, texture_size.y))
						view_preview.set_viewport(SDC::FloatRect.new((240 + 200) / 1280, (60 + 600 - 5 - 300) / 720, 400 / 1280 , 300 / 720))

						SDC.window.use_view(view_preview) do
							SDC.draw_texture(index: "#{config.path}_#{i}".to_sym, coordinates: SDC.xy(0, 0), z: 1)
						end

						i += 1
					end
				end
			end

		end

	end
end