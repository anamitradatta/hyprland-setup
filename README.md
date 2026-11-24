run command ```sudo -E ./setup_hyprland.sh``` to install

## Wi-Fi lid restore

`scripts/wifi-lid-restore.sh` watches logind's `LidClosed` property and re-powers
the iwd adapter (`phy0` by default) whenever the lid is opened. This works around
Realtek/rtw88 adapters coming back from a lid/power transition with the adapter
still powered off, which leaves iwd unable to autoconnect.

The setup script installs it to `~/.local/bin/scripts/` and enables the
`wifi-lid-restore.service` user unit from `configs/systemd/user/`. It is enabled
for the next login but is not started during setup, so the setup script never
touches the active network connection.

Set `WIFI_ADAPTER` in the environment if the adapter is not `phy0`.
