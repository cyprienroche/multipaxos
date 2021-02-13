
# distributed algorithms, n.dulay 29 jan 2021
# coursework, paxos made moderately complex

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
  max_requests: 5_000,		# max requests each client will make
  client_sleep: 2,		# time (ms) to sleep before sending new request
  client_stop:  60_000,		# time (ms) to stop sending further requests
  client_send:	:round_robin,	# :round_robin, :quorum or :broadcast

  n_accounts:   100,		# number of active bank accounts
  max_amount:   1_000,		# max amount moved between accounts

  print_after:  1_000,		# print transaction log summary every print_after msecs

  crash_server: %{},

  init_timeout: 400, # initial timeout a leader might wait before it tries to get a new ballot_num
  min_timeout: 100, # minimum timeout a leader might wait before it tries to get a new ballot_num
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

def params :many_requests_broadcast do # doesnt work
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :max_requests, 2 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:round_robin	# :round_robin, :quorum or :broadcast
end

def params :slow_broadcast do # doesnt work..?
# note: don't look at lag, look at client requests and db updates
  config = params :default
  config = Map.put config, :client_sleep, 50
  config = Map.put config, :max_requests, 20 # stop after 1 requests sent
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end


 # ---------------------- TODO ----------------


def params :slow do
  config = params :default
  config = Map.put config, :client_sleep, 500 # make a request every half second
  config = Map.put config, :max_requests, 10 # stop after 10 requests sent
 _config = config
end

def params :round_robin do
  config = params :slow
  _config = Map.put config, :client_send,	:round_robin	# :round_robin, :quorum or :broadcast
end

def params :quorum do
  config = params :slow
  _config = Map.put config, :client_send,	:quorum	# :round_robin, :quorum or :broadcast
end

def params :broadcast do
  config = params :slow
  _config = Map.put config, :client_send,	:broadcast	# :round_robin, :quorum or :broadcast
end

# ADD YOUR OWN PARAMETER FUNCTIONS HERE

end # module ----------------------------------------------------------------
