#!/usr/bin/env bash
# CallMix: a virtual sink carrying your mic + whatever you are hearing, so a
# single device records both sides of a call.
#
# The sink is always present so it can be picked in a recorder, but the loopbacks
# feeding it are built only while something is actually recording CallMix.monitor.
# A loopback on the Bluetooth monitor keeps the A2DP transport permanently
# acquired, and the headset gives audio to whichever device is streaming — so a
# always-on loopback silently stops a phone from ever taking the headset over.
set -u

CARD=pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp
BUILTIN_MONITOR="alsa_output.${CARD}__sink.monitor"
BUILTIN_JACK_MIC="alsa_input.${CARD}__source"
BUILTIN_DMIC="alsa_input.${CARD}_6__source"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/callmix-setup.lock"

# Apps that latch onto whatever mic existed at launch and never re-read the
# default. Their capture streams get moved for them, which they cannot detect.
STICKY_APPS="teams-for-linux"

source_names() { pactl list short sources 2>/dev/null | awk '{print $2}'; }

source_index() { pactl list short sources 2>/dev/null | awk -v n="$1" '$2 == n {print $1; exit}'; }

sink_exists() { pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qx CallMix; }

desired_out() {
  local bt
  bt=$(source_names | grep -m1 '^bluez_output\..*\.monitor$')
  echo "${bt:-$BUILTIN_MONITOR}"
}

desired_mic() {
  local bt
  # The Bluetooth mic only exists in HSP/HFP, so it appears only once a call app
  # has moved the card off A2DP. Never force that switch here — it drops LDAC.
  bt=$(source_names | grep -m1 '^bluez_input\.')
  if [ -n "$bt" ]; then
    echo "$bt"
  elif [ "$(amixer -c 0 cget iface=CARD,name='Mic Jack' 2>/dev/null | grep -o 'values=\(on\|off\)')" = "values=on" ]; then
    echo "$BUILTIN_JACK_MIC"
  else
    echo "$BUILTIN_DMIC"
  fi
}

# How many streams are actively recording CallMix.monitor. Our own loopbacks read
# the hardware and write into CallMix, so they never count themselves. Corked
# readers must not count: Firefox parks a paused stream on its selected input
# indefinitely, which would hold the legs — and the headset — up forever.
callmix_readers() {
  local idx
  idx=$(source_index CallMix.monitor)
  if [ -z "$idx" ]; then
    echo 0
    return
  fi
  pactl list source-outputs 2>/dev/null | awk -v want="$idx" '
    function flush() { if (src == want && corked == "no") n++; src = ""; corked = "" }
    /^Source Output #/ { flush() }
    /^\tSource: / { src = $2 }
    /^\tCorked: / { corked = $2 }
    END { flush(); print n+0 }'
}

loaded_sources() {
  pactl list short modules 2>/dev/null |
    awk '$2 == "module-loopback" && /sink=CallMix/ {
      for (i = 1; i <= NF; i++) if ($i ~ /^source=/) { sub(/^source=/, "", $i); print $i }
    }' | sort
}

retarget_apps() {
  local mic="$1" want idx
  want=$(source_index "$mic")
  [ -n "$want" ] || return 0

  # Only stream indexes already on the wrong source, so a move never re-triggers
  # itself through the event it generates.
  for idx in $(pactl list source-outputs 2>/dev/null | awk -v apps=" $STICKY_APPS " -v want="$want" '
    function flush() {
      if (idx != "" && index(apps, " " bin " ") && src != want) print idx
      idx = ""; src = ""; bin = ""
    }
    /^Source Output #/ { flush(); idx = substr($3, 2) }
    /^\tSource: / { src = $2 }
    /application\.process\.binary = / { bin = $3; gsub(/"/, "", bin) }
    END { flush() }
  '); do
    pactl move-source-output "$idx" "$mic" 2>/dev/null
  done
}

ensure_sink() {
  sink_exists && return 0
  pactl load-module module-null-sink \
    sink_name=CallMix \
    sink_properties=device.description=CallMix >/dev/null
}

# Only the loopbacks. The null sink pins no hardware, so it is left in place to
# stay selectable; a loopback pinned to a device that later disappears wedges the
# whole graph, so it must never outlive us.
unload_legs() {
  local id
  for id in $(pactl list short modules 2>/dev/null |
    awk '$2 == "module-loopback" && /sink=CallMix/ {print $1}'); do
    pactl unload-module "$id" 2>/dev/null
  done
}

build_legs() {
  local src
  # F1 mutes @DEFAULT_SINK@; if CallMix was ever the default it gets muted, and
  # WirePlumber restores that mute on every recreate — a muted sink records silence.
  pactl set-sink-mute CallMix 0
  for src in "$1" "$2"; do
    pactl load-module module-loopback \
      source="$src" \
      sink=CallMix \
      latency_msec=50 \
      adjust_time=0 \
      source_dont_move=true \
      sink_dont_move=true >/dev/null
  done
}

reconcile() {
  local mic out
  ensure_sink
  mic=$(desired_mic)
  retarget_apps "$mic"

  if [ "$(callmix_readers)" -gt 0 ]; then
    out=$(desired_out)
    if [ "$(loaded_sources)" != "$(printf '%s\n%s\n' "$out" "$mic" | sort)" ]; then
      unload_legs
      build_legs "$out" "$mic"
    fi
  elif [ -n "$(loaded_sources)" ]; then
    unload_legs
  fi
}

# One watcher is enough; a sway reload re-runs this script, and the instance
# already holding the lock keeps the graph correct on its own.
exec 9>"$LOCK"
flock -n 9 || exit 0

trap 'unload_legs' EXIT INT TERM

reconcile

# Switching a Bluetooth card between A2DP and HSP/HFP destroys and recreates its
# nodes, which permanently kills a loopback pinned to them, so rebuild on device
# changes too — not just when a recorder comes and goes.
pactl subscribe 2>/dev/null | while read -r event; do
  case "$event" in
    *"on card"* | *"on source"* | *"on sink"*) ;;
    *) continue ;;
  esac
  # Coalesce the burst, but cap the wait: unrelated traffic (every pactl
  # invocation on the system emits client events) must not defer this forever.
  settle_until=$((SECONDS + 3))
  while [ "$SECONDS" -lt "$settle_until" ] && read -r -t 1 _; do :; done
  reconcile
done
