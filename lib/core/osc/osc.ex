defmodule OSC do
  @moduledoc """
  A faire...
  """

  alias OSC.Encoder
  alias OSC.Parser

  @spec encode(Encoder.t(), Keyword.t()) :: {:ok, iodata()} | {:ok, String.t()} | {:error, {:invalid, any()}}
  def encode(value, options \\ []) do
    {:ok, encode!(value, options)}
  rescue
    exception in [OSC.EncodeError] -> {:error, {:invalid, exception.value}}
  end

  @spec encode_to_iodata(Encoder.t(), Keyword.t()) :: {:ok, iodata()} | {:error, {:invalid, any()}}
  def encode_to_iodata(value, options \\ []) do
    encode(value, [iodata: true] ++ options)
  end

  @spec encode!(Encoder.t(), Keyword.t()) :: iodata() | no_return()
  def encode!(value, options \\ []) do
    iodata = Encoder.encode(value, options)

    if options[:iodata],
      do: iodata,
      else: IO.iodata_to_binary(iodata)
  end

  @spec encode_to_iodata!(Encoder.t(), Keyword.t()) :: iodata() | no_return()
  def encode_to_iodata!(value, options \\ []) do
    encode!(value, [iodata: true] ++ options)
  end

  @spec decode(iodata(), Keyword.t()) :: {:ok, Parser.t()} | {:error, :invalid} | {:error, {:invalid, String.t()}}
  def decode(iodata, options \\ []) do
    Parser.parse(iodata, options)
  end

  @spec decode!(iodata(), Keyword.t()) :: Parser.t() | no_return()
  def decode!(iodata, options \\ []) do
    Parser.parse!(iodata, options)
  end
end
