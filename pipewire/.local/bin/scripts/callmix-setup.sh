#!/usr/bin/env bash
# CallMix: a virtual sink carrying your mic + whatever you are hearing, so a
# single device records both sides of a call. Prefers Bluetooth, falls back to
# the built-in card, and re-applies itself whenever the devices change.
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

loaded_sources() {
  pactl list short modules 2>/dev/null |
    awk '$2 == "module-loopback" && /sink=CallMix/ {
      for (i = 1; i <= NF; i++) if ($i ~ /^source=/) { sub(/^source=/, "", $i); print $i }
    }' | sort
}

sink_exists() { pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qx CallMix; }

source_index() { pactl list short sources 2>/dev/null | awk -v n="$1" '$2 == n {print $1; exit}'; }

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

apply() {
  local out="$1" mic="$2" id
  for id in $(pactl list short modules 2>/dev/null |
    awk '$2 ~ /^module-(null-sink|loopback)$/ && /CallMix/ {print $1}'); do
    pactl unload-module "$id" 2>/dev/null
  done

  pactl load-module module-null-sink \
    sink_name=CallMix \
    sink_properties=device.description=CallMix >/dev/null || return 1

  # F1 mutes @DEFAULT_SINK@; if CallMix was ever the default it gets muted, and
  # WirePlumber restores that mute on every recreate — a muted sink monitors silence.
  pactl set-sink-mute CallMix 0

  for src in "$out" "$mic"; do
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
  local out mic
  out=$(desired_out)
  mic=$(desired_mic)
  if ! sink_exists || [ "$(loaded_sources)" != "$(printf '%s\n%s\n' "$out" "$mic" | sort)" ]; then
    apply "$out" "$mic"
  fi
  retarget_apps "$mic"
}

# One watcher is enough; a sway reload re-runs this script, and the instance
# already holding the lock keeps the graph correct on its own.
exec 9>"$LOCK"
flock -n 9 || exit 0

# Bluetooth auto-reconnect lands several seconds after login, so poll rather
# than sleeping a fixed amount — otherwise we always start on the built-in card.
for _ in $(seq 12); do
  [ -n "$(source_names | grep -m1 '^bluez_output\.')" ] && break
  sleep 1
done

reconcile

# Switching a Bluetooth card between A2DP and HSP/HFP destroys and recreates its
# nodes, which permanently kills any loopback pinned to them — so rebuild on
# every device change rather than only at login.
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
