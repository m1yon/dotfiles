#!/usr/bin/env bash
# Maps opencode-notifier tokens to ntfy.sh publish fields
# Args: event message sessionTitle agentName projectName timestamp turn

event="${1}"
message="${2}"
session_title="${3}"
agent_name="${4}"
project="${5}"
timestamp="${6}"
turn="${7}"

priority=3
tags=""

case "$event" in
  error)            priority=5; tags="warning,skull" ;;
  permission)       priority=4; tags="question" ;;
  question)         priority=4; tags="grey_question" ;;
  complete)         priority=3; tags="heavy_check_mark,partying_face" ;;
  plan_exit)        priority=3; tags="clipboard" ;;
  subagent_complete) priority=2; tags="robot" ;;
  user_cancelled)    priority=2; tags="no_entry" ;;
  session_started)   priority=2; tags="rocket" ;;
  client_connected)  priority=2; tags="electric_plug" ;;
  user_message)      priority=1; tags="speech_balloon" ;;
esac

# Build title: prefer session_title, fall back to event
title="$event"
[ -n "$session_title" ] && title="$session_title"

# Append agent name for subagent events
[ -n "$agent_name" ] && title="$title (@$agent_name)"

# Build body with metadata footer
nl=$'\n'
body="$message"
footer=""
[ -n "$project" ]   && footer="${footer}${project}"
[ -n "$project" ]   && footer="${footer} · "
[ -n "$turn" ]       && footer="${footer}Turn #${turn}"
[ -n "$turn" -a -n "$timestamp" ] && footer="${footer} · "
[ -n "$timestamp" ]  && footer="${footer}${timestamp}"
[ -n "$footer" ] && body="${body}${nl}${nl}──${nl}${footer}"

curl -s \
  -H "Authorization: $NTFY_AUTH_TOKEN" \
  -H "Title: $title" \
  -H "Priority: $priority" \
  -H "Tags: $tags" \
  -H "Markdown: yes" \
  -d "$body" \
  https://ntfy.sh/opencode-michael-lyon
