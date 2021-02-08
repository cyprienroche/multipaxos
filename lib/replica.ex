
# cyprienroche 12 feb 2021

defmodule ReplicaState do
  @enforce_keys [ :config, :database, :leaders ]
  defstruct(
    config: Map.new,
    database: 0,
    leaders: [],
    slot_in: 1,
    slot_out: 1,
    requests: MapSet.new,
    proposals: MapSet.new,
    decisions: MapSet.new)

	def new(config, database, leaders) do
		%ReplicaState{
      config: config,
      database: database,
      leaders: leaders }
	end # new

end # ReplicaState

defmodule Replica do

def start config, database do
  receive do
      { :BIND, leaders } ->
        next ReplicaState.new(config, database, leaders)
    end
end # start

defp next state do
  receive do
    { :CLIENT_REQUEST, cmd } ->
      send state.config.monitor, { :CLIENT_REQUEST, state.config.node_num }
      cmd

    { :DECISION, _slot, cmd } ->
      cmd
  end # receive

  # propose()
  next state
end # next

end # Replica
