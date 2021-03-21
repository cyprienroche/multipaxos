
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
