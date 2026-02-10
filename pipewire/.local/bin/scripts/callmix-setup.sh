#!/usr/bin/env bash
set -e

# Small delay to let PipeWire, bluetooth, and Pulse compatibility come up
sleep 3

#device=$(pactl list cards short | awk '/88_C9_E8_DD_29_7F/ {print $1}')
#pactl set-card-profile "$device" a2dp-sink-ldac

# Optional: clean old instances if they exist
for id in $(pactl list short modules | awk '/module-null-sink|module-loopback/ {print $1}'); do
  pactl unload-module "$id" || true
done

# Create CallMix virtual sink
pactl load-module module-null-sink \
  sink_name=CallMix \
  sink_properties=device.description=CallMix

# Loop Speaker + Headphones OUTPUT (what you hear) into CallMix
pactl load-module module-loopback \
  source=alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink.monitor \
  sink=CallMix \
  latency_msec=50 \
  adjust_time=0 \
  source_dont_move=true \
  sink_dont_move=true

# Select mic: headset mic if plugged in, otherwise built-in digital mic
MIC_JACK=$(amixer -c 0 cget iface=CARD,name='Mic Jack' | grep -o 'values=\(on\|off\)')
if [ "$MIC_JACK" = "values=on" ]; then
  MIC_SOURCE=alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__source
else
  MIC_SOURCE=alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source
fi

# Loop microphone INPUT into CallMix
pactl load-module module-loopback \
  source="$MIC_SOURCE" \
  sink=CallMix \
  latency_msec=50 \
  adjust_time=0 \
  source_dont_move=true \
  sink_dont_move=true
