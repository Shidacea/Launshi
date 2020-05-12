module SDC
	module Debug

		ACTIVE = true

		def self.measure_time(&block)
			return nil if !ACTIVE
			t0 = Time.now
			block.call
			return Time.now - t0
		end

		def self.log_time(msg, &block)
			return if !ACTIVE
			t = self.measure_time do
				block.call
			end
			self.log(msg.to_s + t.to_s)
		end

		def self.log(message)
			return if !ACTIVE
			puts message
		end

	end
end