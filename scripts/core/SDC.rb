module SDC

	C_NEWLINE = "\n"
	C_CAR_RET = "\r"
	C_TAB = "\t"
	C_BACKSPACE = "\b"
	C_CTRL_BACK = "\x7F"

	# Basic attributes

	@window = nil
	@scene = nil
	@next_scene = nil
	@game = nil
	@limiter = nil
	@text_input = nil

	def self.window
		return @window
	end

	def self.window=(value)
		@window = value
	end

	def self.scene
		return @scene
	end

	def self.scene=(value)
		@scene = value
	end

	def self.next_scene
		return @next_scene
	end

	def self.next_scene=(value)
		@next_scene = value
	end

	def self.game
		return @game
	end

	def self.game=(value)
		@game = value
	end

	def self.limiter
		return @limiter
	end

	def self.limiter=(value)
		@limiter = value
	end

	def self.text_input
		return @text_input 
	end

	def self.text_input=(value)
		@text_input = value
	end

	# Script routines for easier readability, directly referencing other methods

	def self.key_pressed?(key, override_text_input: false)
		return @window.has_focus? && (override_text_input || !@text_input) && SDC::EventKey.const_defined?(key) && SDC::EventKey.is_pressed?(SDC::EventKey.const_get(key))
	end

	def self.key(key)
		return SDC::EventKey.const_get(key) if SDC::EventKey.const_defined?(key)
	end

	def self.mouse_button_pressed?(button)
		return @window.has_focus? && SDC::EventMouse.const_defined?(button) && SDC::EventMouse.is_button_pressed?(SDC::EventMouse.const_get(button))
	end

	def self.mouse_button(button)
		return SDC::EventMouse.const_get(button) if SDC::EventMouse.const_defined?(button)
	end

	# Returns an integer array with two elements of the pixel coordinates.
	# Therefore, window scaling WILL change the dimensions of the area the mouse can operate in.
	def self.get_mouse_pos
		return SDC::EventMouse.get_position(SDC.window)
	end

	# Returns the mouse coordinate for the current view.
	# If you want to check for another view, you need to activate it first or execute any mouse check methods in a view block.
	def self.get_mouse_coords
		return SDC::EventMouse.get_coordinates(SDC.window)
	end

	def self.get_mouse_point
		return SDC::ShapePoint.new(self.get_mouse_coords)
	end

	def self.right_klick?
		return self.mouse_button_pressed?(:Right)
	end

	def self.left_klick?
		return self.mouse_button_pressed?(:Left)
	end

	def self.get_variable(index, default: nil)
		return @game.get_variable(index, default: default)
	end

	def self.set_variable(index, value)
		@game.set_variable(index, value)
	end

	def self.get_switch(index)
		return @game.get_switch(index)
	end

	def self.set_switch(index, value: true)
		@game.set_switch(index, value: value)
	end

	def self.reset_switch(index, value: false)
		@game.set_switch(index, value: value)
	end

	def self.toggle_switch(index)
		@game.toggle_switch(index)
	end

	def self.increase_variable(index, value = 1, default: 0)
		@game.increase_variable(index, value, default: default)
	end

	def self.decrease_variable(index, value = 1, default: 0)
		@game.decrease_variable(index, value, default: default)
	end

	def self.multiply_variable(index, value, default: 0)
		@game.multiply_variable(index, value, default: default)
	end

	# Other utility methods for rapid development

	def self.draw_texture(index: nil, filename: nil, coordinates: SDC::Coordinates.new)
		texture = nil
		if filename then
			if index then
				texture = SDC::Data.load_texture(index, filename: filename)
			else
				# TODO: Maybe transfer this ability into the Data class itself for the case of index = 0
				texture = SDC::Data.load_texture((SDC::Data::SYMBOL_PREFIX + filename).to_sym, filename: filename)
			end

		elsif index then
			texture = SDC::Data.textures[index]
			puts "Warning: Texture index #{index} not loaded." if !texture

		else
			raise("No arguments given for texture drawing")

		end

		sprite = SDC::Sprite.new
		sprite.link_texture(texture)
		SDC.window.draw_translated(sprite, coordinates)
	end

	# TODO: Simplify and make universal caching functions
	def self.draw_text(index: nil, font_index: nil, text: "", size: 10, coordinates: SDC::Coordinates.new, color: nil)
		font = SDC::Data.fonts[font_index]

		text_obj = nil
		if text then
			if index then
				if SDC::Data.texts[index] then
					text_obj = SDC::Data.texts[index]
				else
					SDC::Data.add_text(SDC::Text.new(text, font, size), index: index)
					text_obj = SDC::Data.texts[index]
				end
			else
				# TODO: Used object ID or magic number instead, maybe a dummy object
				sym = (SDC::Data::SYMBOL_PREFIX + text).to_sym
				cached_obj = SDC::Data.texts[sym]

				SDC::Data.add_text(SDC::Text.new(text, font, size), index: sym) if !cached_obj
				text_obj = SDC::Data.texts[sym]
			end
			text_obj.string = text

		elsif index then
			text_obj = SDC::Data.texts[index]

		else
			raise("No arguments given for text drawing")

		end

		text_obj.color = color if color

		SDC.window.draw_translated(text_obj, coordinates)
	end

	def self.handle_backspace_input(text_buffer)
		text_buffer.chop!
	end

	def self.handle_ctrl_backspace_input(text_buffer)
		# Remove the last word and every whitespace after it
		text_buffer.rstrip!
		last_space = text_buffer.rindex(" ")
		if last_space then
			text_buffer[last_space+1..-1] = ""
		else
			text_buffer.clear
		end
	end

	# TODO: Allow specific input class

	def self.process_text_input(event: nil, text_buffer: nil, override: false)
		if event.has_type?(:TextEntered) then
			char = event.text_char

			# Want to filter certain chars? Use the filter method!
			if block_given? then
				filter_result = yield(char, text_buffer)
				char = filter_result if filter_result
				return if override
			end

			if char == C_NEWLINE then
				
			elsif char == C_CAR_RET then

			elsif char == C_TAB then

			elsif char == C_BACKSPACE then
				self.handle_backspace_input(text_buffer)
			elsif char == C_CTRL_BACK then
				self.handle_ctrl_backspace_input(text_buffer)
			else
				text_buffer.concat(char)
			end
		end
	end

end