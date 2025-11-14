-- Create CallMix virtual sink at startup
table.insert(components, {
  name = "CallMix",
  type = "pipewire-module",
  args = {
    "module-null-sink",
    "sink_name=CallMix",
    "sink_properties=device.description=CallMix"
  }
})

-- Loop WH-1000XM5 output (what you hear) into CallMix
table.insert(components, {
  name = "CallMix-output",
  type = "pipewire-module",
  args = {
    "module-loopback",
    "source=bluez_output.88_C9_E8_DD_29_7F.1.monitor",
    "sink=CallMix",
    "latency_msec=1"
  }
})

-- Loop WH-1000XM5 microphone into CallMix
table.insert(components, {
  name = "CallMix-input",
  type = "pipewire-module",
  args = {
    "module-loopback",
    "source=bluez_input.88_C9_E8_DD_29_7F.0",
    "sink=CallMix",
    "latency_msec=1"
  }
})
