rule = {
  matches = {
    {
      { "device.name", "matches", "alsa_card.*" },
    },
  },
  apply_properties = {
    ["api.acp.auto-profile"] = true,
    ["api.acp.auto-port"] = true,
  },
}

table.insert(alsa_monitor.rules, rule)
