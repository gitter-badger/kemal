require "option_parser"
require "./kemal/*"

at_exit do
  OptionParser.parse! do |opts|
    opts.on("-p ", "--port ", "port") do |opt_port|
      Kemal.config.port = opt_port.to_i
    end
    opts.on("-e ", "--environment ", "environment") do |env|
      Kemal.config.env = env
    end
  end

  config = Kemal.config
  logger = Kemal::Logger.new
  config.add_handler logger
  config.add_handler Kemal::Handler::INSTANCE
  config.add_handler HTTP::StaticFileHandler.new("./public")

  server = HTTP::Server.new(config.port, config.handlers)
  server.ssl = config.ssl
  logger.write "[#{config.env}] Kemal is ready to lead at #{config.scheme}://0.0.0.0:#{config.port}\n"

  Signal::INT.trap {
    logger.write "Kemal is going to take a rest!\n"
    logger.write "#{Time.now} - Bye Bye!\n\n"
    logger.handler.close
    server.close
    exit
  }

  # This route serves the built-in images for not_found and exceptions.
  get "/__kemal__/:image" do |env|
    image = env.params["image"]
    file_path = File.expand_path("libs/kemal/images/#{image}", Dir.working_directory)
    env.add_header "Content-Type", "application/octet-stream"
    File.read(file_path)
  end

  server.listen
end
