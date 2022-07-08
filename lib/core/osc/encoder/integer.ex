defimpl OSC.Encoder, for: Integer do
  @limit_32 2_147_483_647
  @limit_64 9_223_372_036_854_775_808

  @spec encode(integer(), Keyword.t()) :: bitstring()
  def encode(integer, _options) when integer >= 0 and integer < @limit_32 do
    <<integer::big-size(32)>>
  end

  def encode(integer, _options) when integer >= 0 and integer < @limit_64 do
    <<integer::big-size(64)>>
  end

  @spec flag(integer()) :: byte()
  def flag(integer) when abs(integer) < @limit_32, do: ?i
  def flag(integer) when abs(integer) < @limit_64, do: ?h

  # for {flag, size, limit} <- [{?i, 32, 2_147_483_647}, {?h, 64, 9_223_372_036_854_775_808}] do
  #   def encode(integer, _) when abs(integer) < unquote(limit) do
  #     <<integer::big-size(unquote(size))>>
  #   end

  #   def flag(integer) when abs(integer) < unquote(limit) do
  #     unquote(flag)
  #   end
  # end
end
