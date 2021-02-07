
# cyprienroche 12 feb 2021

defmodule Leader do

def start config do
  Debug.info(config, "Starting Leader#{config.node_num}")
end # start

end # Leader
