#!/bin/bash

messages=(
  "Hello there 👋"
  "Welcome back, Coder 😎"
  "System ready 🚀"
  "Another day, another build ⚡"
  "Hyprland loaded 🔥"
  "Let’s get things done 💻"
  "All systems operational 🟢"
)

random_msg=${messages[$RANDOM%${#messages[@]}]}

notify-send "$random_msg"
