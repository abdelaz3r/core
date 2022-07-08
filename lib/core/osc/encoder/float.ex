defimpl OSC.Encoder, for: Float do
  @spec encode(float(), Keyword.t()) :: bitstring()
  def encode(float, _options) do
    <<float::big-float-size(32)>>
  end

  # Maybe support 64 bit
  # @spec encode(float(), Keyword.t()) :: bitstring()
  # def encode(float, _options) do
  #   <<float::big-float-size(64)>>
  # end

  @spec flag(float()) :: byte()
  def flag(_), do: ?f
end
