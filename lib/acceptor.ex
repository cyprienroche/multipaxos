
# cyprienroche 12 feb 2021

defmodule AcceptorState do
  @enforce_keys [ :config ]
  defstruct(
    config: Map.new,
    ballot_num: nil,
    accepted: MapSet.new)

	def new(config) do
		%AcceptorState{
      config: config }
	end # new

end # AcceptorState

defmodule Acceptor do

def start config do
  next AcceptorState.new(config)
end # start

defp next state do
  receive do
    { :P1A, _from, ballot_num } ->
      ballot_num

    { :P2A, _from, { ballot_num, _, _ } = pvalue } ->
      pvalue
  end # receive

  next state
end # next

end # Acceptor
