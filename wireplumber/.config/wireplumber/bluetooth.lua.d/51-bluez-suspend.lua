-- Release the A2DP transport sooner once playback stops.
--
-- Multipoint handover is gated on the sink suspending: the headset cannot give
-- audio to the phone while this machine still holds the transport. WirePlumber's
-- default is 5s (scripts/suspend-node.lua), which is the pause-to-handover lag.
-- Going too low churns A2DP/LDAC renegotiation and clips the start of the next
-- sound, so 2s is the compromise. 0 would disable suspend entirely — the worst
-- case here, as the transport would never be released.
table.insert(bluez_monitor.rules, {
  matches = {
    {
      { "node.name", "matches", "bluez_output.*" },
    },
  },
  apply_properties = {
    ["session.suspend-timeout-seconds"] = 2,
  },
})
