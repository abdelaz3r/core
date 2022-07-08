defmodule Test.Core.OscTest do
  @moduledoc false

  use ExUnit.Case

  @data [
    %{
      args: [],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 0, 0, 0>>,
      iodata: [["/foo", 0, 0, 0, 0], [',', 0, 0, 0], []]
    },
    %{
      args: ["hello"],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 115, 0, 0, 104, 101, 108, 108, 111, 0, 0, 0>>,
      iodata: [["/foo", 0, 0, 0, 0], [',s', 0, 0], [["hello", 0, 0, 0]]]
    },
    %{
      args: [2],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 2>>,
      iodata: [["/foo", 0, 0, 0, 0], [',i', 0, 0], [<<0, 0, 0, 2>>]]
    },
    %{
      args: [9_223_372_036_854_775_805],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 2>>,
      iodata: [["/foo", 0, 0, 0, 0], [',h', 0, 0], ["\d\xFF\xFF\xFF\xFF\xFF\xFF\xFD"]]
    },
    %{
      args: [2.0],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 102, 0, 0, 64, 0, 0, 0>>,
      iodata: [["/foo", 0, 0, 0, 0], [',f', 0, 0], [<<64, 0, 0, 0>>]]
    },
    %{
      args: [true],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 84, 0, 0>>,
      iodata: [["/foo", 0, 0, 0, 0], [',T', 0, 0], [[]]]
    },
    %{
      args: [:foo],
      bitstring: <<47, 102, 111, 111, 0, 0, 0, 0, 44, 83, 0, 0, 102, 111, 111, 0>>,
      iodata: [["/foo", 0, 0, 0, 0], [',S', 0, 0], [["foo", 0]]]
    }
  ]

  describe "OSC encoding" do
    test "OSC.encode/2 with various args" do
      Enum.each(@data, fn %{args: args, bitstring: bitstring} ->
        {:ok, return} = OSC.encode(%OSC.Message{address: "/foo", arguments: args})
        assert return == bitstring
      end)
    end

    test "OSC.encode_to_iodata/2 with various args" do
      Enum.each(@data, fn %{args: args, iodata: iodata} ->
        {:ok, return} = OSC.encode_to_iodata(%OSC.Message{address: "/foo", arguments: args})
        assert return == iodata
      end)
    end

    test "OSC.encode!/2 with various args" do
      Enum.each(@data, fn %{args: args, bitstring: bitstring} ->
        return = OSC.encode!(%OSC.Message{address: "/foo", arguments: args})
        assert return == bitstring
      end)
    end

    test "OSC.encode_to_iodata!/2 with various args" do
      Enum.each(@data, fn %{args: args, iodata: iodata} ->
        return = OSC.encode_to_iodata!(%OSC.Message{address: "/foo", arguments: args})
        assert return == iodata
      end)
    end

    test "OSC.decode/2 with various args" do
      Enum.each(@data, fn %{args: args, iodata: iodata} ->
        {:ok, %OSC.Packet{contents: %OSC.Message{address: "/foo", arguments: return}}} = OSC.decode(iodata)
        assert return == args
      end)
    end

    test "OSC.decode!/2 with various args" do
      Enum.each(@data, fn %{args: args, iodata: iodata} ->
        %OSC.Packet{contents: %OSC.Message{address: "/foo", arguments: return}} = OSC.decode!(iodata)
        assert return == args
      end)
    end
  end
end
