# Launshi module with helper functions and singleton instance variables

module SDC
	class Launshi

		AVAILABLE_GENRES = ["Demo", "Shooter", "Platformer", "Fighting", "Survival", 
			"Adventure", "Horror", "Visual novel", "RPG", "Roguelike", 
			"Simulation", "Strategy", "Sports", "Racing", "Board game", 
			"Card game", "Turn-based", "Puzzle", "Logic", "Party",
			"Action", "Adult", "Tool", "Utility"].sort

		attr_accessor :name_filter, :description_filter, :genre_filters, :keyword_filters

		def self.set_definite_exit
			@definite_exit = true
		end

		def self.definite_exit
			return @definite_exit
		end

		class Config

			attr_reader :path, :json
			
			def initialize(path, config_json)
				@path = path
				@json = config_json
			end

		end

		def initialize
			reset_configs
			reset_filters
		end

		def reset_configs
			@configs = []
			@filtered_configs = []

			self.class.reset_final_config
		end

		def reset_filters
			@name_filter = ""
			@description_filter = ""
			@genre_filters = []
			@keyword_filters = []
		end

		def load_configs(path, create_if_missing: false)
			if !Dir.exists?(path) then
				Dir.mkdir(path)
			end
			Dir.foreach(path) do |entry|
				if !entry.start_with?(".") && File.directory?(path + "/" + entry) then
					Dir.foreach(path + "/" + entry) do |content|
						if !content.start_with?(".") && !File.directory?(path + "/" + entry + "/" + content) then
							if /project(_[a-zA-Z\d]+)?.json/.match(content) then
								new_config = self.load_config_file(path + "/" + entry, content)

								@configs.push(new_config)

								load_thumbnail(new_config)
								load_screenshots(new_config)
							end
						end
					end
				end
			end
		end

		def self.reset_final_config
			@final_config = nil
		end

		def self.set_final_config(index, instance)
			@final_config = instance.get_filtered_configs[index]
		end

		def self.get_final_config
			return @final_config
		end

		def get_configs
			return @configs
		end

		def get_filtered_configs
			return @filtered_configs
		end

		def apply_filters
			@filtered_configs = []
			@configs.each do |config|
				next if @name_filter.length > 0 && !config.json["title"].index(@name_filter)
				next if @description_filter.length > 0 && !config.json["subtitle"].index(@description_filter) && !config.json["description"].index(@description_filter)

				genre_found = false
				count = 0
				0.upto(AVAILABLE_GENRES.size - 1) do |i|
					if @genre_filters[i] then
						genre_found = true if config.json["genres"].index(AVAILABLE_GENRES[i])
						count += 1
					end
				end
				next if count > 0 && @genre_filters.size > 0 && !genre_found

				keyword_found = false
				@keyword_filters.each do |keyword_filter|
					keyword_found = true if config.json["keywords"].index(keyword_filter)
				end
				next if @keyword_filters.size > 0 && !keyword_found

				@filtered_configs.push(config)
			end
		end

		def load_config_file(path, filename)
			full_name = path + "/" + filename
		
			content = ""
			file = File.open(full_name, "r")
			while !file.eof?
				content += file.readline
			end

			file.close

			return Config.new(path, JSON.parse(content))
		end

		def self.load_scripts(config)
			config.json["scripts"]&.each do |script|
				if script.end_with?("/") then
					SDC::Script.load_recursively(script.chop)
				elsif script.end_with?(".rb") then
					SDC::Script.load(script)
				else
					raise("Invalid file to load: #{script}")
				end
			end
		end

		def load_thumbnail(config)
			old_path = SDC::Script.path
			SDC::Script.path = config.path
			SDC::Data.load_texture(config.path.to_sym, filename: config.json["thumbnail"]) if config.json["thumbnail"] && !config.json["thumbnail"].empty?
			SDC::Script.path = old_path
		end

		def load_screenshots(config)
			old_path = SDC::Script.path
			SDC::Script.path = config.path
			i = 0
			config.json["screenshots"]&.each do |screenshot|
				SDC::Data.load_texture("#{config.path}_#{i}".to_sym, filename: screenshot["file"]) if screenshot["file"]
				i += 1
			end
			SDC::Script.path = old_path
		end

		def check_version(config)
			project_version = config.json["shidacea_version"]&.split(".")
			return false if !project_version

			sdc_version = SDC::Script.version.split(".")

			return false if project_version[0].to_i > sdc_version[0].to_i
			return nil if project_version[0].to_i < sdc_version[0].to_i
			return false if project_version[1].to_i > sdc_version[1].to_i
			return nil if project_version[0].to_i < 1 && project_version[1].to_i < sdc_version[1].to_i
			return true
		end

	end
end