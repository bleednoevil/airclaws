#!/bin/bash

# AirClaws - macOS Version (Tested on 2017 macOS i5 & 2022 Apple M1)
# Author: Ray Cervantes aka $pill_bl**d
# nobloodyregrets@gmail.com
# www.linkedin.com/in/raycervantes
# For Research/Educational/Art Purposes Only If Cited Correctly
# Any Commercial Use is a Violation of United States Laws & Bleed No Evil
# Created 2/22/2026
# AirBleed 📡🩸 Proof of Concept Prototype: AirClaws
# © 2026 Ray Cervantes

# Executes by Bluetooth, Wi-Fi, & Cellular.
# Loading command while audio playing requires a pause press then a play press again to execute command (2x button press).
# Loading command while audio paused requires a play/pause/play press to execute command (3x button press).
# To run the same command two or more times consecutively track press away from payload and back to payload must be performed to execute same payload again.
# Loading Commands can also be done by entering 'Command##' with specific number and Command in the name field area of a device in the iCloud such as an iPhone, iPad, or AirPod.
# Commands can also be executed by entering 'AVRCP Play' in name field area of iOS device (iPhone, iPad) connected to iCloud of macOS host/target device or send bluetooth connection attempt to host/target.
# First name change to 'AVRCP Play' will execute command but next name change to 'AVRCP Play' should add letters or numbers after to be logged in log stream and execute command as soon as name is changed.
# User can root in and run AirClaws on remote machine or run at startup.
# Code may need to be altered for differnt macOS versions
# Volume Mappings can be added to load specific channel triggers or add more features.
# Future Commands, Command pack ideas, and collaborations are welcome
# Run chmod +x airclaws.sh before starting
# Ctrl + C to exit

PRED='eventMessage CONTAINS "AVRCP Next Track" || eventMessage CONTAINS "AVRCP Previous Track" || eventMessage CONTAINS "Command" || eventMessage CONTAINS "AVRCP Play"'

current_index=0
total_commands=100
loaded_command=""
loaded_cmd=""

# Define commands 0–99, or as many as you can think of.
# declare -A commands
commands[0]='curl -s -X POST http://localhost:8000/api/v1/agents/0/run > /dev/null'
commands[1]='curl -s -X POST http://localhost:8000/api/v1/agents/1/run > /dev/null'
commands[2]='curl -s -X POST http://localhost:8000/api/v1/agents/2/run > /dev/null'
commands[3]='curl -s -X POST http://localhost:8000/api/v1/agents/3/run > /dev/null'
commands[4]='curl -s -X POST http://localhost:8000/api/v1/agents/4/run > /dev/null'
commands[5]='curl -s -X POST http://localhost:8000/api/v1/agents/5/run > /dev/null'
commands[6]='curl -s -X POST http://localhost:8000/api/v1/agents/6/run > /dev/null'
commands[7]='curl -s -X POST http://localhost:8000/api/v1/agents/7/run > /dev/null'
commands[8]='curl -s -X POST http://localhost:8000/api/v1/agents/8/run > /dev/null'
commands[9]='curl -s -X POST http://localhost:8000/api/v1/agents/9/run > /dev/null'

# Generate remaining commands with simple echo commands
for i in $(seq 10 $((total_commands-1))); do
  commands[$i]="echo \"Command $i executed at \$(date)\" >> ~/Users/your_macos_username/airclawslog.txt"
done

# Function to load/arm command (not execute yet)
arm_command() {
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  loaded_command="Command $current_index"
  loaded_cmd="${commands[$current_index]}"
  echo "$ts  [ARMED] $loaded_command → waiting for AVRCP Play"
}

# Function to execute command for AI Agent
execute_command() {
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  if [[ -n "$loaded_cmd" ]]; then
    echo "$ts  [EXECUTE] $loaded_command"
    eval "$loaded_cmd" &
    loaded_command=""
    loaded_cmd=""
  else
    echo "$ts  [INFO] AVRCP Play seen but no command armed"
  fi
}

# Monitor log stream
/usr/bin/log stream --style syslog --info --predicate "$PRED" \
| while IFS= read -r line; do 
  ts=$(date '+%Y-%m-%d %H:%M:%S')

  # Direct trigger if "Command##" found in log
  if [[ "$line" =~ Command([0-9]{1,3}) ]]; then
    num="${BASH_REMATCH[1]}"
    if (( num >= 0 && num < total_commands )); then
      current_index=$num
      echo "$ts  [NEXT] Jumped to Command $current_index"
      arm_command
    fi
    continue
  fi

  # Next Track → increment command
  if [[ "$line" == *"AVRCP Next Track"* ]]; then
    if (( current_index < total_commands-1 )); then
      ((current_index++))
    fi
    echo "$ts  [NEXT] Switched to Command $current_index"
    arm_command
    continue
  fi

  # Previous Track → decrement command
  if [[ "$line" == *"AVRCP Previous Track"* ]]; then
    if (( current_index > 0 )); then
      ((current_index--))
    fi
    echo "$ts  [NEXT] Switched to Command $current_index"
    arm_command
    continue
  fi

  # Play → execute loaded command
  if [[ "$line" == *"AVRCP Play"* ]]; then
    execute_command
    continue
  fi
  done
