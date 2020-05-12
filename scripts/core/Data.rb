module SDC
	module Data

		# If an actual symbol is not needed, e.g. for one-time draw routines
		SYMBOL_PREFIX = "_UNKNOWN_"

		extend SDCMeta::DataStorage

		self.define_new_data_type(:entity, plural: :entities, as_hash: true)
		self.define_new_data_type(:font, as_hash: true)
		self.define_new_data_type(:text, as_hash: true)
		self.define_new_data_type(:tileset, as_hash: true)
		self.define_new_data_type(:texture, as_hash: true)
		self.define_new_data_type(:sound_buffer, as_hash: true)
		self.define_new_data_type(:music_track, as_hash: true)
		self.define_new_data_type(:map_config, as_hash: true)
		self.define_new_data_type(:filename, as_hash: true)

		# TODO: Generate meta-methods for these

		def self.load_texture(file_index, filename: nil)
			filename = self.filenames[file_index] if !filename

			if !self.textures[file_index] then
				texture = SDC::Texture.new
				texture.load_from_file(filename)
				self.add_texture(texture, index: file_index)
			end

			return self.textures[file_index]
		end

		def self.preload_texture(file_index, filename)
			self.add_filename(filename, index: file_index)
			self.load_texture(file_index)
		end

		def self.load_sound_buffer(file_index, filename: nil)
			filename = self.filenames[file_index] if !filename

			if !self.sound_buffers[file_index] then
				sound_buffer = SDC::SoundBuffer.new
				sound_buffer.load_from_file(filename)
				self.add_sound_buffer(sound_buffer, index: file_index)
			end

			return self.sound_buffers[file_index]
		end

		def self.preload_sound_buffer(file_index, filename)
			self.add_filename(filename, index: file_index)
			self.load_sound_buffer(file_index)
		end

		def self.load_music(file_index, filename: nil)
			filename = self.filenames[file_index] if !filename

			if !self.music_tracks[file_index] then
				music = SDC::Music.new
				music.open_from_file(filename)
				self.add_music_track(music, index: file_index)
			end

			return self.music_tracks[file_index]
		end

		def self.preload_music(file_index, filename)
			self.add_filename(filename, index: file_index)
			self.load_music(file_index)
		end

		def self.load_font(file_index, filename: nil)
			filename = self.filenames[file_index] if !filename

			if !self.fonts[file_index] then
				font = SDC::Font.new
				font.load_from_file(filename)
				self.add_font(font, index: file_index)
			end

			return self.fonts[file_index]
		end

	end
end