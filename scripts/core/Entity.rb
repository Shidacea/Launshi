# Base entity class

module SDC
	class Entity

		# AI module

		include SDCMeta::AIBackend

		# Specific class properties
		# You may easily add your own properties.

		extend SDCMeta::ClassProperty

		self.define_class_property(:living, default: false)
		self.define_class_property(:gravity_multiplier, default: 1.0)
		self.define_class_property(:ai_active, default: false)
		self.define_class_property(:max_hp, default: 0)

		# Accessor methods for content arrays (except for textures)

		attr_accessor :sprites, :boxes, :shapes, :hitshapes, :hurtshapes, :active_sprites

		# Physics-based accessor methods

		attr_accessor :position, :velocity
	
		# Accessor methods for living entities
	
		attr_accessor :hp

		# Other accessor methods

		attr_reader :magic_number

		# Class methods for adding different objects to any entity
	
		def self.add_box(index: nil, offset: Coordinates.new, size: nil)
			if !size then
				raise("No size given for box with index #{index}")
			end

			@boxes = SDC::SpecialContainer.new if !@boxes
			@boxes.add(SDC::ShapeBox.new(offset, size), index)
		end

		def self.add_shape(index: nil, type: nil, offset: SDC::Coordinates.new, radius: nil, size: nil, semiaxes: nil, direction: nil)
			@shapes = SDC::SpecialContainer.new if !@shapes
			shape = nil

			if type == SDC::ShapePoint then
				shape = type.new(offset)
			elsif type == SDC::ShapeLine then
				raise("Direction not defined for line shape with index #{index}") if !direction
				shape = type.new(offset, direction)
			elsif type == SDC::ShapeCircle then
				raise("Radius not defined for line shape with index #{index}") if !radius
				shape = type.new(offset, radius)
			elsif type == SDC::ShapeBox then
				raise("Size not defined for line shape with index #{index}") if !size
				shape = type.new(offset, size)
			elsif type == SDC::ShapeTriangle then
				# TODO
				shape = type.new
			elsif type == SDC::ShapeQuadrangle then
				# TODO
				shape = type.new
			elsif type == SDC::ShapeEllipse then
				raise("Semiaxes not defined for line shape with index #{index}") if !semiaxes
				shape = type.new(offset, axes)
			else
				raise("Unknown shape type #{type} for shape index #{index}")
			end

			@shapes.add(shape, index)
		end

		def self.add_sprite(index: nil, active: true, texture_index: nil, offset: SDC::Coordinates.new, rect: nil)
			@sprites = SDC::SpecialContainer.new if !@sprites
			@sprites.add([texture_index, offset, active, rect], index)
		end

		def self.set_hitshape(index: nil, active: true, shape_index: nil, damage: 0, attributes: {})
			@hitshapes = SDC::SpecialContainer.new if !@hitshapes
			@hitshapes.add(SDC::Hitshape.new(damage: damage, shape_index: shape_index, active: active, attributes: attributes), index)
		end

		def self.set_hurtshape(index: nil, active: true, shape_index: nil, attributes: {})
			@hurtshapes = SDC::SpecialContainer.new if !@hurtshapes
			@hurtshapes.add(SDC::Hurtshape.new(active: active, shape_index: shape_index, attributes: attributes), index)
		end

		def self.register_id(index)
			@entity_id = SDC::Data.add_entity(self, index: index)
		end

		def self.entity_id
			return @entity_id
		end

		# Class getter methods for utility and code readability

		def self.all_boxes
			@boxes = SDC::SpecialContainer.new if !@boxes
			return @boxes
		end

		def self.all_shapes
			@shapes = SDC::SpecialContainer.new if !@shapes
			return @shapes
		end

		def self.all_sprites
			@sprites = SDC::SpecialContainer.new if !@sprites
			return @sprites
		end

		def self.all_hitshapes
			@hitshapes = SDC::SpecialContainer.new if !@hitshapes
			return @hitshapes
		end

		def self.all_hurtshapes
			@hurtshapes = SDC::SpecialContainer.new if !@hurtshapes
			return @hurtshapes
		end

		# Create local copies of all boxes/shapes/...

		def load_boxes
			@boxes = []
			all_boxes = self.class.all_boxes

			0.upto(all_boxes.size - 1) do |i|
				element = all_boxes.get(i)

				@boxes[i] = element.dup if element
			end
		end

		def load_shapes
			@shapes = []
			all_shapes = self.class.all_shapes

			0.upto(all_shapes.size - 1) do |i|
				element = all_shapes.get(i)

				@shapes[i] = element.dup if element
			end
		end

		def load_sprites
			@sprites = []
			@active_sprites = []
			all_sprites = self.class.all_sprites

			0.upto(all_sprites.size - 1) do |i|
				element = all_sprites.get(i)

				# Again this time, the objects should not be copied to avoid useless memory consumption

				if element then
					texture_index = element[0]
					@sprites[i] = SDC::Sprite.new
					@sprites[i].position = element[1]
					@active_sprites[i] = element[2]

					if texture_index then
						@sprites[i].link_texture(SDC::Data.textures[texture_index])
					end

					@sprites[i].texture_rect = element[3] if element[3]
				end
			end

			def load_hitshapes
				@hitshapes = []
				all_hitshapes = self.class.all_hitshapes

				0.upto(all_hitshapes.size - 1) do |i|
					element = all_hitshapes.get(i)

					@hitshapes[i] = element.dup if element
				end
			end

			def load_hurtshapes
				@hurtshapes = []
				all_hurtshapes = self.class.all_hurtshapes

				0.upto(all_hurtshapes.size - 1) do |i|
					element = all_hurtshapes.get(i)

					@hurtshapes[i] = element.dup if element
				end
			end

		end

		# Actual instance methods which should not be changed

		def initialize(param: nil)
			@param = param

			initialization_procedure
		end

		def initialization_procedure
			@parent = nil
			@children = []
			@position = SDC::Coordinates.new
			@velocity = SDC::Coordinates.new
			@acceleration = SDC::Coordinates.new

			setup_ai
			
			@last_collisions = []

			# Set a magic number to identify parent-child-structures
			@magic_number = self.object_id

			load_boxes
			load_shapes
			load_sprites
			load_hitshapes
			load_hurtshapes

			if self.living then
				full_heal
				@invincibility_frame_counter = 0
				@invincibility_next_frame = false
			end

			at_init
		end

		def physics
			accelerate(SDC.game.gravity * self.gravity_multiplier)

			@velocity += @acceleration * SDC.game.dt
			@position += @velocity * SDC.game.dt

			# Debug floor
			if @position.y > 500.0 then
				@position.y = 500.0
				@velocity.y = 0.0
			end

			@acceleration.x = 0.0
			@acceleration.y = 0.0
		end

		def basic_hit(hurtshape, hitshape)
			if @invincibility_frame_counter == 0 then
				total_damage = hitshape.damage
				inflict_damage(total_damage)
			end
		end

		def inflict_damage(value)
			@hp -= value
			@hp = 0 if @hp <= 0
			@invincibility_next_frame = true
		end

		def full_heal
			@hp = self.max_hp
		end

		def living_procedure
			@invincibility_frame_counter -= 1 if @invincibility_frame_counter > 0
			if @invincibility_next_frame then
				@invincibility_next_frame = false
				@invincibility_frame_counter = 60
			end
		end

		def accelerate(vector)
			@acceleration += vector
		end

		def absolute_position
			return (@parent ? @position + @parent.absolute_position : @position)
		end

		def set_parent(entity)
			@parent = entity
			broadcast_magic_number(entity.magic_number)
		end

		def set_child(entity)
			@children.push(entity)
			entity.set_parent(self)
		end

		def broadcast_magic_number(number)
			@magic_number = number
			@children.each {|child| child.cascade_magic_number(number)}
		end

		def test_box_collision_with(other_entity)
			# Avoid collisions between identical entities and its children
			return nil if magic_number == other_entity.magic_number

			@boxes.each do |box|
				other_entity.boxes.each do |other_box|
					result = SDC::Collider.test(box, absolute_position, other_box, other_entity.absolute_position)
					return other_box if result
				end
			end

			return nil
		end

		def test_shape_collision_with(other_entity)
			return nil if magic_number == other_entity.magic_number

			@shapes.each do |shape|
				other_entity.shapes.each do |other_shape|
					result = SDC::Collider.test(shape, absolute_position, other_shape, other_entity.absolute_position)
					return other_shape if result
				end
			end

			return nil
		end

		def each_colliding_action_shape(other_entity)
			return nil if magic_number == other_entity.magic_number

			other_position = other_entity.absolute_position

			0.upto(@hurtshapes.size - 1) do |hurtshape_index|
				hurtshape = @hurtshapes[hurtshape_index]
				next if !hurtshape || !hurtshape.active

				shape = @shapes[hurtshape.shape_index]

				0.upto(other_entity.hitshapes.size - 1) do |hitshape_index|
					hitshape = other_entity.hitshapes[hitshape_index]
					next if !hitshape || !hitshape.active

					other_shape = other_entity.shapes[hitshape.shape_index]

					if SDC::Collider.test(shape, absolute_position, other_shape, other_position) then
						yield hurtshape, hitshape
					end
				end
			end
		end

		def draw(window)
			# This function draws each sprite at its designated position
			# The offset of the sprite position relative to the entity position is included

			0.upto(@sprites.size - 1) do |i|
				sprite = @sprites[i]
				next if !sprite || !@active_sprites[i]
				window.draw_translated(sprite, absolute_position)
			end
		end

		def update
			living_procedure

			custom_update

			if self.ai_active then
				tick_ai
			end

			physics if !@parent

			@last_collisions.clear
		end

		def collision_with_entity(other_entity, hurtshape, hitshape)
			@last_collisions.push(other_entity)

			if self.living then
				basic_hit(hurtshape, hitshape)
			end

			at_entity_collision(other_entity, hurtshape, hitshape)
		end

		def collided_with(&condition)
			return @last_collisions.index(&condition)
		end

		def collided_with_class(klass)
			return @last_collisions.index {|e| e.is_a?(klass)}
		end

		def collided_with_property(property_symbol, value: true)
			return @last_collisions.index {|e| e.send(property_symbol) == value}
		end

		# Custom routines which can be redefined for inherited objects

		def at_init
		
		end

		def custom_update

		end

		def custom_draw

		end

		def at_entity_collision(other_entity, hurtshape, hitshape)
		
		end

		def at_tile_collision(tile)

		end

	end
end