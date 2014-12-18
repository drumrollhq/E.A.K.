queuer = ->
  queue = []
  fn = (type, a, b) ->
    # TODO: make sure no duplicates are added to the queue
    queue[*] = {type, a, b}

  fn.queue = queue
  fn

contact-find = (id) ->
  | id in @a.ids => [@a, @b]
  | id in @b.ids => [@b, @a]
  | otherwise => throw new Error "Cannot find '#id' in contact"

send = (queue, channel) ->
  for item in queue.queue
    {a, b, type} = item
    type = if type is '+' then 'start' else 'end'
    channel.publish {type, a, b, find: contact-find}

module.exports = events = (state, channel) ->
  queue = queuer!

  for node in state.dynamics
    contacts = node.contacts or []
    prev-contacts = node.prev-contacts or []

    # Queue events for added things
    for contact in contacts
      unless contact in prev-contacts
        queue '+', node, contact

    # queue events for removed things
    for contact in prev-contacts
      unless contact in contacts
        queue '-', node, contact

  send queue, channel
