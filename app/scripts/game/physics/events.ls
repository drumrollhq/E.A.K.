queuer = ->
  queue = []
  fn = (type, a, b) ->
    # TODO: make sure no duplicates are added to the queue
    # ALLOC
    queue[*] = {type, a, b}

  fn.queue = queue
  fn

contact-find = (id) ->
  # ALLOC
  | id in @a.ids => [@a, @b]
  # ALLOC
  | id in @b.ids => [@b, @a]
  | otherwise => throw new Error "Cannot find '#id' in contact"

send = (queue, channel) ->
  for item in queue.queue
    {a, b, type} = item
    type = if type is '+' then 'start' else 'end'
    # ALLOC
    channel.publish {type, a, b, find: contact-find}

module.exports = events = (state, channel) ->
  queue = queuer!

  for node in state.dynamics
    contacts = node.contacts or []
    prev-contacts = node.prev-contacts or []

    # Queue events for added things
    for contact in contacts
      unless contact in prev-contacts
        # ALLOC
        queue '+', node, contact

    # queue events for removed things
    for contact in prev-contacts
      unless contact in contacts
        # ALLOC
        queue '-', node, contact

  send queue, channel
