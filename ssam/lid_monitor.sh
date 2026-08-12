#!/system/bin/sh
# lid_monitor.sh - Surface Type Cover smart lid daemon
#
# Surface Pro 8/9 report cover (lid) posture through the SAM EC, but the
# kernel never maps "cover closed" to the ACPI SW_LID switch. This daemon
# polls the posture sysfs node and synthesizes SW_LID events so Android's
# lid_behavior (sleep on close) works with the physical cover.
#
# Policy:
#   - Cover closed : display off (SW_LID=1). With config_useAutoSuspend=false
#                    the system stays awake, so Wi-Fi/ADB stay connected.
#   - Cover opened : display on (SW_LID=0 + KEYCODE_WAKEUP).
#   - Smart sleep  : if the cover stays closed and no audio is playing for
#                    LID_SLEEP_TIMEOUT seconds, write "mem" to
#                    /sys/power/state to really suspend (music/headphones
#                    keep the system awake until playback stops).
#
# Tune the idle timeout with:  LID_SLEEP_TIMEOUT=<seconds>

STATE=/sys/bus/surface_aggregator/devices/01:26:01:00:01/state
LID=/dev/input/event0
LID_SLEEP_TIMEOUT=${LID_SLEEP_TIMEOUT:-300}

# The SAM posture device can enumerate a few seconds after boot-complete,
# so wait for it before entering the polling loop.
wait_count=0
while [ ! -r "$STATE" ] && [ "$wait_count" -lt 60 ]; do
	sleep 1
	wait_count=$((wait_count + 1))
done
log -t lid_monitor "started (state=$STATE)"

# Resolve the lid switch event node dynamically (its number can change
# across boots / device enumeration order).
for e in /sys/class/input/event*; do
	if [ "$(cat "$e/device/name" 2>/dev/null)" = "Lid Switch" ]; then
		LID=/dev/input/${e##*/}
		break
	fi
done

# True if any ALSA playback stream is running (music, video, ringtone...).
audio_active() {
	for s in /proc/asound/card*/pcm*p/sub*/status; do
		[ -r "$s" ] || continue
		if grep -q 'state: RUNNING' "$s" 2>/dev/null; then
			return 0
		fi
	done
	return 1
}

last=
closed_since=
while true; do
	s=$(cat "$STATE" 2>/dev/null)
	if [ "$s" = "closed" ]; then
		if [ "$last" != "closed" ]; then
			sendevent "$LID" 5 0 1
			sendevent "$LID" 0 0 0
			last=closed
			closed_since=$(date +%s)
		fi

		# Smart deep-sleep: only when idle for a while and no audio.
		if [ -n "$closed_since" ]; then
			now=$(date +%s)
			if [ $((now - closed_since)) -ge "$LID_SLEEP_TIMEOUT" ] &&
			   ! audio_active; then
				echo mem > /sys/power/state 2>/dev/null
			fi
		fi
	else
		if [ "$last" = "closed" ]; then
			sendevent "$LID" 5 0 0
			sendevent "$LID" 0 0 0
			# Wake the display on cover open.
			input keyevent 224
			last=
			closed_since=
		fi
	fi
	sleep 1
done
