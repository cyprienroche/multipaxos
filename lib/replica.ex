
# cyprienroche 12 feb 2021

defmodule Replica do

def start config, _database do
  Debug.info(config, "Starting Replica#{config.node_num}")
end # start

end # Replica
