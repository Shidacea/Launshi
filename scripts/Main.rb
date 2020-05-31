# Scene for Launshi

main_routine(SDC::Launshi::SceneLaunshi, title: 'Shidacea - Launshi', width: 1280, height: 720)

# Some scripts and containers will be resetted, thus the old window will be terminated

begin

	SDC::Data.clear_containers

	final_config = SDC::Launshi.get_final_config

	if final_config then

		SDC::Script.path = SDC::Launshi.get_final_config.path
		SDC::Launshi.load_scripts(SDC::Launshi.get_final_config)

	end

rescue Exception => exc
	f = File.open("log.txt", "a")

	f.puts "Error in Launshi at #{Time.now}:"
	f.puts exc.inspect
	f.puts exc.backtrace.join("\n")
	f.puts ""

	f.close

	raise exc
end