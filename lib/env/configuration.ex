
defmodule Configuration do

def node_id(config, node_type, node_num \\ "") do
  Map.merge config,
  %{
    node_type:     node_type,
    node_num:      node_num,
    node_name:     "#{node_type}#{node_num}",
    node_location: Util.node_string(),
  }
end

def start_module(config, module_type) do
  config = Map.put config, :module, module_type
  _config = Debug.create_module_log_file(config)
end # start_module

def start_module(config, module_type, name_extension) do
  config = Map.put config, :module, module_type
  _config = Debug.create_module_log_file(config, name_extension)
end # start_module

# -----------------------------------------------------------------------------

def params :default do
  %{
  max_requests: 5,	        	# max requests each client will make
  client_sleep: 2,		        # time (ms) to sleep before sending new request
  client_stop:  20_000,		    # time (ms) to stop sending further requests
  client_send:	:round_robin,	# :round_robin, :quorum or :broadcast

  n_accounts:   100,		      # number of active bank accounts
  max_amount:   1_000,	    	# max amount moved between accounts

  print_after:  1_000,		    # print transaction log summary every print_after msecs

  crash_server: %{},

  init_timeout: 400,          # initial timeout a leader might wait before it tries to get a new ballot_num
  min_timeout: 1,             # minimum timeout a leader might wait before it tries to get a new ballot_num
  timeout_factor: 1.5,
  timeout_constant: 150,

  }
end

# -----------------------------------------------------------------------------

def params :faster do
  config = params :default	# settings for faster throughput
 _config = Map.merge config,
  %{
  # ADD YOUR OWN PARAMETERS HERE
  }
end

# -----------------------------------------------------------------------------

def params :debug1 do		# same as :default with debug_level: 1
  config = params :default
 _config = Map.put config, :debug_level, 1
end

def params :debug3 do		# same as :default with debug_level: 3
  config = params :default
 _config = Map.put config, :debug_level, 3
end

def params :one_request_round_robin do # works
  config = params :default
  config = Map.put config, :max_requests, 1 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:round_robin	# :round_robin, :quorum or :broadcast
end

def params :one_request_quorum do # works
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 1 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:quorum	# :round_robin, :quorum or :broadcast
end

def params :one_request_broadcast do # works
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 1 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

def params :two_requests_broadcast do # works
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 2 # each db should do 2 * 5 = 10 updates
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

def params :five_requests_broadcast do # works 2/3 of the time with 5 servers
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 5 # each db should do 5 * 5 = 25 updates
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

def params :ten_requests_broadcast do # works with 2 servers
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 10 # each db should do 10 * 5 = 50 updates
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

def params :twenty_requests_broadcast do # works with 2 servers
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 20 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

def params :crash_server_1 do # works
  config = params :default
  _config = Map.put config, :crash_server, %{1 => 1}
end

def params :crash_server_4_and_5 do # works
  config = params :default
  _config = Map.put config, :crash_server, %{4 => 5000, 5 => 10000}
end

end # module ----------------------------------------------------------------
