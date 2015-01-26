require! {
  'lib/channels'
  'game/event-loop'
}

$body = $ document.body

channels.game-commands.subscribe ({command}) ->
  if command in <[pause resume]> then console.error 'Event-loop pause commands are deprecated!'
  switch command
  | 'pause' => req-pause!
  | 'resume' => req-resume!
  | 'force-pause' => pause!
  | 'force-resume' => resume!

# Keep track of the number of times the game has been paused or resumed.
# This way, we can recieve multiple pause requests, but will only resume
# once we have an equal number of resume requests.
pause-requests = 0

# Are we currently in the paused state?
paused = false

# Should the event-loop be running when we resume?
event-loop-resume = null

req-pause = ->
  pause-requests += 1
  check-paused!

req-resume = ->
  if pause-requests > 0 then pause-requests -= 1
  check-paused!

check-paused = ->
  | pause-requests is 0 and paused => channels.game-commands.publish command: 'force-resume'
  | pause-requests > 0 and not paused => channels.game-commands.publish command: 'force-pause'

pause = ->
  $body.add-class 'paused'
  event-loop-resume := not event-loop.paused
  event-loop.pause!
  paused := true

resume = ->
  $body.remove-class 'paused'
  if event-loop-resume then event-loop.resume!
  paused := false
