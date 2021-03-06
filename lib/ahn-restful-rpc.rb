begin
  require 'rack'
  require 'json'
rescue LoadError
  abort "ERROR: restful_rpc requires the 'rack' and 'json' gems"
end

# Don't you love regular expressions? Matches only 0-255 octets. Recognizes "*" as an octet wildcard.
VALID_IP_ADDRESS = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|\*)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|\*)$/

def ip_allowed?(ip)
  raise ArgumentError, "#{ip.inspect} is not a valid IP address!" unless ip.kind_of?(String) && ip =~ VALID_IP_ADDRESS

  octets = ip.split "."

  case COMPONENTS.send(:'ahn-restful-rpc')["access"]
    when "everyone"
      true
    when "whitelist"
      whitelist = COMPONENTS.send(:'ahn-restful-rpc')["whitelist"]
      !! whitelist.find do |pattern|
        pattern_octets = pattern.split "."
        # Traverse both arrays in parallel
        octets.zip(pattern_octets).map do |octet, octet_pattern|
          octet_pattern == "*" ? true : (octet == octet_pattern)
        end == [true, true, true, true]
      end
    when "blacklist"
      blacklist = COMPONENTS.send(:'ahn-restful-rpc')["blacklist"]
      ! blacklist.find do |pattern|
        pattern_octets = pattern.split "."
        # Traverse both arrays in parallel
        octets.zip(pattern_octets).map do |octet, octet_pattern|
          octet_pattern == "*" ? true : (octet == octet_pattern)
        end == [true, true, true, true]
      end
    else
      raise Adhearsion::Components::ConfigurationError, 'Unrecognized "access" configuration value!'
  end
end

RESTFUL_API_HANDLER = lambda do |env|
  json = env["rack.input"].read

  # Return "Bad Request" HTTP error if the client forgot
  return [400, {}, "You must POST a valid JSON object!"] if json.blank?

  json = JSON.parse json

  nesting = COMPONENTS.send(:'ahn-restful-rpc')["path_nesting"]
  path = env["PATH_INFO"]

  return [404, {}, "This resource does not respond to #{path.inspect}"] unless path[0...nesting.size] == nesting

  path = path[nesting.size..-1]

  return [404, {"Content-Type" => "application/json"}, "You cannot nest method names!"] if path.include?("/")

  rpc_object = Adhearsion::Components.component_manager.extend_object_with(Object.new, :rpc)

  # TODO: set the content-type and other HTTP headers
  response_object = rpc_object.send(path, *json)
  if defined? response_object.headers
    return [200, {"Content-Type" => "application/json"}, Array(response_object.headers.to_json)]
  end
  
  [200, {"Content-Type" => "application/json"}, Array(response_object.to_json)]

end

initialization do
  config = COMPONENTS.send :'ahn-restful-rpc'

  api = RESTFUL_API_HANDLER

  port            = config["port"] || 5000
  authentication  = config["authentication"]
  show_exceptions = config["show_exceptions"]
  handler         = Rack::Handler.const_get(config["handler"] || "Mongrel")

  if authentication
    api = Rack::Auth::Basic.new(api) do |username, password|
      authentication[username] == password
    end
    api.realm = "Adhearsion API"
  end

  if show_exceptions
    api = Rack::ShowStatus.new(Rack::ShowExceptions.new(api))
  end

  Thread.new do
    handler.run api, :Port => port
  end
end

methods_for :rpc do
  [:send_action, :introduce, :originate, :call_into_context, :call_and_exec, :ping].each do |method_name|
    define_method("restful_#{method_name}") do |*args|
      if VoIP::Asterisk.manager_interface
        response = VoIP::Asterisk.manager_interface.send(method_name, *args)
        {:result => true}
      else
        ahn_log.ami_remote.error "AMI has not been enabled in startup.rb!"
        {:result => false}
      end
    end
  end
end
