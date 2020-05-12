module SDCMeta
	module DataStorage

		def define_new_data_type(name, as_hash: false, plural: name.to_s + "s")
			@container_list = []

			instance_variable_set("@#{plural}", (as_hash ? {} : []))
			data = instance_variable_get("@#{plural}")

			define_singleton_method("add_#{name}") do |obj, index: nil|
				if !index then
					if as_hash then
						raise("No index for hash data type given") 
					else
						index = data.size
					end
				end
				data[index] = obj
				return index
			end
		
			define_singleton_method(plural) do
				return data
			end

			@container_list.push(instance_variable_get("@#{plural}"))
		end

		def clear_containers
			@container_list.each do |container|
				container.clear
			end
		end

	end
end