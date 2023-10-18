# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

defmodule Core.Backend.Config do
  @moduledoc """
  A struct representing the configuration for the backend
  """

  alias Core.Backend.Config

  @type t :: %Config{
          application: String.t(),
          jack_out: String.t(),
          jack_in: String.t(),
          wrapper_path: String.t(),
          backend_path: String.t(),
          protocol: atom(),
          port: non_neg_integer(),
          control_busses: non_neg_integer(),
          audio_busses: non_neg_integer(),
          block_size: non_neg_integer(),
          hardware_buffer_size: non_neg_integer() | nil,
          use_system_clock: non_neg_integer(),
          samplerate: non_neg_integer(),
          buffers: non_neg_integer(),
          max_nodes: non_neg_integer(),
          max_synthdefs: non_neg_integer(),
          rt_memory: non_neg_integer(),
          wires: non_neg_integer(),
          randomseeds: non_neg_integer(),
          load_synthdefs: non_neg_integer(),
          rendezvous: non_neg_integer(),
          max_logins: non_neg_integer(),
          password: boolean(),
          nrt: boolean(),
          memory_locking: boolean(),
          version: boolean(),
          hardware_device_name: boolean(),
          verbose: non_neg_integer(),
          ugen_search_path: boolean(),
          restricted_path: boolean(),
          threads: non_neg_integer(),
          socket_address: String.t(),
          inchannels: non_neg_integer(),
          outchannels: non_neg_integer()
        }

  defstruct application: "scsynth",
            jack_out: "system:playback_1,system:playback_2",
            jack_in: "system:capture_1,system:capture_2",
            wrapper_path: "scripts/backend-wrapper.sh",
            backend_path: "/Applications/SuperCollider.app/Contents/Resources/",
            protocol: :tcp,
            port: 57_110,
            control_busses: 16_384,
            audio_busses: 1024,
            block_size: 64,
            hardware_buffer_size: nil,
            use_system_clock: 0,
            samplerate: 44_100,
            buffers: 1024,
            max_nodes: 1024,
            max_synthdefs: 1024,
            rt_memory: 8192,
            wires: 64,
            randomseeds: 64,
            load_synthdefs: 1,
            rendezvous: 0,
            max_logins: 64,
            password: false,
            nrt: false,
            memory_locking: false,
            version: false,
            hardware_device_name: false,
            verbose: 0,
            ugen_search_path: false,
            restricted_path: false,
            threads: 4,
            socket_address: "127.0.0.1",
            inchannels: 8,
            outchannels: 8

  @spec to_cmd_format(Config.t()) :: list()
  def to_cmd_format(config) do
    [
      Path.join([config.backend_path, config.application]),
      [
        if(config.protocol == :tcp, do: ["-t"], else: ["-u"]),
        "#{config.port}"
      ],
      ["-c", "#{config.control_busses}"],
      ["-a", "#{config.audio_busses}"],
      ["-z", "#{config.block_size}"],
      if(config.hardware_buffer_size, do: ["-Z", "#{config.hardware_buffer_size}"], else: []),
      if(config.application == "supernova", do: ["-C", "#{config.use_system_clock}"], else: []),
      ["-S", "#{config.samplerate}"],
      ["-b", "#{config.buffers}"],
      ["-n", "#{config.max_nodes}"],
      ["-d", "#{config.max_synthdefs}"],
      ["-m", "#{config.rt_memory}"],
      ["-w", "#{config.wires}"],
      ["-r", "#{config.randomseeds}"],
      ["-D", "#{config.load_synthdefs}"],
      ["-R", "#{config.rendezvous}"],
      ["-l", "#{config.max_logins}"],
      if(config.password, do: ["-p", "#{config.password}"], else: []),
      if(config.nrt, do: ["-N", "#{config.nrt}"], else: []),
      if(config.memory_locking && config.application == "supernova", do: ["--memory-locking"], else: []),
      if(config.hardware_device_name, do: ["-H", "#{config.hardware_device_name}"], else: []),
      ["-V", "#{config.verbose}"],
      if(config.ugen_search_path, do: ["-U", "#{config.ugen_search_path}"], else: []),
      if(config.restricted_path, do: ["-P", "#{config.restricted_path}"], else: []),
      if(config.threads && config.application == "supernova", do: ["--threads"], else: []),
      if(config.threads && config.application == "supernova", do: ["#{config.threads}"], else: []),
      ["-B", "#{config.socket_address}"],
      ["-i", "#{config.inchannels}"],
      ["-o", "#{config.outchannels}"]
    ]
    |> List.flatten()
  end
end
