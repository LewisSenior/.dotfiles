#!/usr/bin/env bash
set -e

# Small delay to let PipeWire, bluetooth, and Pulse compatibility come up
sleep 3

device=$(pactl list cards short | awk '/88_C9_E8_DD_29_7F/ {print $1}')
pactl set-card-profile "$device" headset-head-unit-msbc

# Optional: clean old instances if they exist
for id in $(pactl list short modules | awk '/module-null-sink|module-loopback/ {print $1}'); do
  pactl unload-module "$id" || true
done

# Create CallMix virtual sink
pactl load-module module-null-sink \
  sink_name=CallMix \
  sink_properties=device.description=CallMix

# Loop WH-1000XM5 OUTPUT (what you hear) into CallMix
pactl load-module module-loopback \
  source=bluez_output.88_C9_E8_DD_29_7F.1.monitor \
  sink=CallMix \
  latency_msec=1

# Loop WH-1000XM5 INPUT (mic) into CallMix
pactl load-module module-loopback \
  source=bluez_input.88_C9_E8_DD_29_7F.0 \
  sink=CallMix \
  latency_msec=1
