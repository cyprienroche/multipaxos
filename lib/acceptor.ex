
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
  config = Configuration.start_module(config, :acceptor)
  next AcceptorState.new(config)
end # start

defp next state do
  receive do
    { :P1A, scout, ballot_num } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a scout")
      state =
        if ballot_num > state.ballot_num do
          Debug.module_info(state.config, "Adopt new ballot_num from a scout")
          AcceptorState.adopt(state, ballot_num)
        else
          Debug.module_info(state.config, "Don't Adopt new ballot_num from a scout")
          state
        end # if
      Debug.module_info(state.config, "Now using ballot_num #{inspect state.ballot_num}")
      Debug.module_info(state.config, "Send ballot_num #{inspect state.ballot_num} to a scout")
      send scout, { :P1B, self(), state.ballot_num, state.accepted }
      next(state)

    { :P2A, commander, { ballot_num, _slot, _cmd } = pvalue } ->
      Debug.module_info(state.config, "Received pvalue #{inspect pvalue} from a commander")
      state =
        if ballot_num == state.ballot_num do
          Debug.module_info(state.config, "Accept pvalue from commander")
          AcceptorState.accept(state, pvalue)
        else
          Debug.module_info(state.config, "Don't accept pvalue from commander")
          state
        end # if
      Debug.module_info(state.config, "Send ballot_num #{inspect state.ballot_num} to commander")
      send commander, { :P2B, self(), state.ballot_num }
      next(state)
  end # receive
end # next

end # Acceptor
