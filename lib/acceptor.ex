
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
  receive do
    { :P1A, scout, ballot_num } ->
      Debug.module_info(state.config, "Acceptor #{state.config.node_num} received ballot_num #{inspect ballot_num} from a scout", :acceptor)
      state =
        if ballot_num > state.ballot_num do
          AcceptorState.adopt(state, ballot_num)
        else
          state
        end # if
      Debug.module_info(state.config, "Acceptor #{state.config.node_num} sending ballot_num #{inspect state.ballot_num} to a scout", :acceptor)
      send scout, { :P1B, self(), state.ballot_num, state.accepted }
      next(state)

    { :P2A, commander, { ballot_num, _slot, _cmd } = pvalue } ->
      Debug.module_info(state.config, "Acceptor #{state.config.node_num} received pvalue #{inspect pvalue} from a commander", :acceptor)
      state =
        if ballot_num == state.ballot_num do
          AcceptorState.adopt(state, pvalue)
        else
          state
        end # if
      Debug.module_info(state.config, "Acceptor #{state.config.node_num} sending ballot_num #{inspect state.ballot_num} to a commander", :acceptor)
      send commander, { :P2B, self(), state.ballot_num }
      next(state)
  end # receive
end # next

end # Acceptor
