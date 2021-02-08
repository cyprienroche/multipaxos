
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

  def adopt(state, ballot_num) do
    %{ state | ballot_num: ballot_num }
  end # adopt

  def accept(state, pvalue) do
    %{ state | accepted: MapSet.put(state.accepted, pvalue) }
  end # accept

end # AcceptorState

defmodule Acceptor do

def start config do
  next AcceptorState.new(config)
end # start

defp next state do
  state = receive do
    { :P1A, scout, ballot_num } ->
      state = if ballot_num > state.ballot_num do
        AcceptorState.adopt(state, ballot_num)
      else
        state
      end # if
      send scout, { :P1B, self(), state.ballot_num, state.accepted }
      state

    { :P2A, commander, { ballot_num, _slot, _cmd } = pvalue } ->
      state = if ballot_num == state.ballot_num do
        AcceptorState.adopt(state, pvalue)
      else
        state
      end # if
      send commander, { :P2B, self(), state.ballot_num }
      state
  end # receive

  next state
end # next

end # Acceptor
