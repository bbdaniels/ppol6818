#!/bin/bash
# PPOL 6818 codespace watch: once no VS Code window has been connected to
# this codespace for five minutes, end everything the student's windows left
# running (the R consoles and every other terminal, the extension hosts with
# the agents and the R language server), so nothing runs unseen and GitHub
# stops the idle codespace at its timeout. VS Code's server would otherwise
# keep a closed window's terminals and extensions running for hours, waiting
# for the window to come back.
#
# A window counts as connected while it holds a connection to the VS Code
# server's port. Started by ppol6818::console_attach() in a codespace; one
# watch per codespace.
exec 9>/tmp/ppol6818-watch.lock
flock -n 9 || exit 0
me=$(id -u)
grace=${PPOL6818_GRACE:-300}
step=15
gone=0
while sleep "$step"; do
  srv=$(pgrep -u "$me" -f 'out/server-main.js' | head -1)
  port=""
  [ -n "$srv" ] && port=$(ss -tlnpH 2>/dev/null | grep "pid=$srv," | awk '{n = split($4, a, ":"); print a[n]; exit}')
  if [ -z "$port" ]; then gone=0; continue; fi
  if [ -n "$(ss -tnH state established "( sport = :$port )" 2>/dev/null)" ]; then gone=0; continue; fi
  gone=$((gone + step))
  [ "$gone" -lt "$grace" ] && continue
  ended=""
  for host in $(pgrep -u "$me" -f -- '--type=extensionHost'); do kill "$host" && ended=1; done
  for pty in $(pgrep -u "$me" -f -- '--type=ptyHost'); do
    for p in $(pgrep -P "$pty"); do pkill -P "$p"; kill "$p" && ended=1; done
  done
  [ -n "$ended" ] && echo "$(date '+%F %T') No VS Code window for $grace seconds: ended its terminals and extensions." >> /tmp/ppol6818-watch.log
  gone=0
done
