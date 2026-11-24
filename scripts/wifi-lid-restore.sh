#!/bin/bash

# Re-enable the iwd Wi-Fi adapter when the laptop lid is opened.
#
# Some Realtek/rtw88 adapters come back from a lid/power transition with the
# adapter left powered off. iwd will not autoconnect while the adapter is off,
# so we watch logind's LidClosed property and flip Powered back on.
#
# Runs as a regular user (iwd's D-Bus policy allows wheel/network members).
# Override the adapter name with WIFI_ADAPTER if phy0 is not correct.

set -u

ADAPTER="${WIFI_ADAPTER:-phy0}"
POLL_INTERVAL="${WIFI_LID_POLL_INTERVAL:-2}"

log()
{
	logger -t wifi-lid-restore -- "$*" 2>/dev/null || true
}

get_lid_closed()
{
	gdbus call --system \
		--dest org.freedesktop.login1 \
		--object-path /org/freedesktop/login1 \
		--method org.freedesktop.DBus.Properties.Get \
		org.freedesktop.login1.Manager LidClosed 2>/dev/null
}

adapter_is_on()
{
	local output
	output=$(timeout 8 iwctl adapter "$ADAPTER" show 2>/dev/null |
		sed -r 's/\x1B\[[0-9;]*[mK]//g')

	grep -qE 'Powered[[:space:]]+on([[:space:]]|$)' <<< "$output"
}

power_on_adapter()
{
	if adapter_is_on; then
		return 0
	fi

	log "adapter $ADAPTER is powered off after lid open; re-enabling"
	if timeout 10 iwctl adapter "$ADAPTER" set-property Powered on >/dev/null 2>&1; then
		log "adapter $ADAPTER re-enabled"
	else
		log "failed to re-enable adapter $ADAPTER (is iwd running and D-Bus access allowed?)"
	fi
}

main()
{
	local previous current

	previous=$(get_lid_closed)
	log "started (adapter=$ADAPTER, initial lid state: ${previous:-unknown})"

	# No action at startup: only a closed -> open transition triggers a change.
	while sleep "$POLL_INTERVAL"; do
		current=$(get_lid_closed)
		[[ -z "$current" ]] && continue

		if [[ "$previous" == *true* && "$current" == *false* ]]; then
			# Let the driver finish bringing the device back before checking it.
			sleep 1
			power_on_adapter
		fi

		previous="$current"
	done
}

main "$@"
