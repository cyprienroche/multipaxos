
# cyprienroche 12 feb 2021

defmodule ScoutState do
  @enforce_keys [ :leader, :acceptors, :ballot_num ]
  defstruct(
    leader: nil,
    acceptors: MapSet.new,
    ballot_num: nil,
    waitfor: MapSet.new,
    pvals: MapSet.new)

	def new(leader, acceptors, ballot_num) do
		%ScoutState{
      leader: leader,
      acceptors: acceptors,
      ballot_num: ballot_num,
      waitfor: MapSet.new(acceptors) }
	end # new

end # ScoutState

defmodule Scout do

def start leader, acceptors, ballot_num do
  # send p1a request to acceptors
  next ScoutState.new(leader, acceptors, ballot_num)
end # start

defp next state do
  receive do
    { :P1B, _from, _ballot_num, pvalue } ->
      pvalue
  end # receive

  next state
end # next

end # Scout
