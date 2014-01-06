queuer = (mediator) ->
  queue = []

  fn = (type, a, b) ->
    # TODO: make sure no duplicates are added to the queue
    queue[*] = {type, a, b}

  fn.queue = queue

  fn

send = (queue, mediator) ->
  for item in queue.queue
    {a, b, type} = item
    type = if type is '+' then 'begin-contact' else 'end-contact'
    for ida in a.ids
      for idb in b.ids
        mediator.trigger "#{type}:#{ida}:#{idb}"
        mediator.trigger "#{type}:#{idb}:#{ida}"

module.exports = events = (state, mediator) ->
  queue = queuer mediator

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

    # if node.contacts and node.contacts.length > 0
    #   console.log node
    #   throw new Error

  send queue, mediator
