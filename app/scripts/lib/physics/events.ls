contact-find = (id) ->
  | id in @a.ids => [@a, @b]
  | id in @b.ids => [@b, @a]
  | otherwise => throw new Error "Cannot find '#id' in contact"

trigger-contacts = (target, contact, type) ->
  target.trigger \contact type, contact
  target.trigger "contact:#type", contact

  for id in contact.ids when id isnt '*'
    target.trigger "contact:#type:#id", contact

send = (type, a, b, channel) ->
  channel.publish {type, a, b, find: contact-find}
  if a.trigger then trigger-contacts a, b, type
  if b.trigger then trigger-contacts b, a, type

module.exports = events = (state, channel) ->
  for node in state.dynamics
    contacts = node.contacts or []
    prev-contacts = node.prev-contacts or []

    # Queue events for added things
    for contact in contacts
      unless contact in prev-contacts
        send \start, node, contact, channel

    # queue events for removed things
    for contact in prev-contacts
      unless contact in contacts
        send \end, node, contact, channel
