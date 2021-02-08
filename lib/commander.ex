
# cyprienroche 12 feb 2021

defmodule CommanderState do
  @enforce_keys [ :leader, :acceptors, :replicas, :pvalue ]
  defstruct(
    leader: 0,
    acceptors: MapSet.new,
    replicas: 0,
    pvalue: MapSet.new,
    waitfor: MapSet.new)

	def new(leader, acceptors, replicas, pvalue) do
		%CommanderState{
      leader: leader,
      acceptors: acceptors,
      replicas: replicas,
      pvalue: pvalue,
      waitfor: MapSet.new(acceptors) }
	end # new

end # CommanderState

defmodule Commander do

def start leader, acceptors, replicas, pvalue do
  # send p2a request to acceptors
  next CommanderState.new(leader, acceptors, replicas, pvalue)
end # start

defp next state do
  receive do
    { :P2B, _from, ballot_num } ->
      ballot_num
  end # receive

  next state
end # next

end # Commander
