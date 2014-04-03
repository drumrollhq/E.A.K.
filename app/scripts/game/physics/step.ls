require! {
  './Vector'
  './Matrix'
  './collision'
  './keys'
  '../mediator'
}

const max-fall-speed = 10px,
  fall-acc = 0.3px,
  max-move-speed = 4px,
  move-acc = 0.3px,
  move-acc-in-air = 0.2px
  move-damp = 0.7px,
  move-damp-in-air = 0.01px
  jump-speed = 5.4px,
  max-jump-frames = 10,
  pad = 0.1

old-els = []
trails = false

update-el = (obj) ->
  if obj.data.player then mediator.trigger 'playermove', obj.p

  t = "translate3d(#{obj.p.x - obj.x}px, #{obj.p.y - obj.y}px, 0)"
  if obj._lt is t then return

  if trails and obj.data.player
    new-el = $ obj.el .clone!
    new-el.insert-after obj.el
    obj.el = new-el.0

    old-els[*] = new-el
    if old-els.length > 250 then old-els.shift!remove!

  obj._lt = t
  obj.el.style.transform = obj.el.style.moz-transform = obj.el.style.webkit-transform = t

{get-aabb, find-bbox-intersects, get-contacts} = collision

is-contact-above = (shape-a, shape-b) --> true
  # shape-a.p.y >= shape-b.y

find-state = (obj, nodes) ->
  contacts = get-contacts obj, nodes

  obj.prev-contacts = obj.contacts
  obj.contacts = contacts

  contacts = contacts |> reject -> it.data?.ignore? or it.data?.sensor?

  # Find contacts we appear to be on top of (naive)
  above-contacts = contacts.filter -> is-contact-above obj

  if above-contacts.length
    contact = head above-contacts
    obj.state = 'contact'
    return {
      type: 'contact'
      thing: contact
    }

  if obj.jump-frames > 0
    obj.state = 'jumping'
    return type: 'jumping'

  obj.state = 'falling'

  {type: 'falling'}

target = 1000 / 60 # Aim for 60fps

ts = replicate 30 1

module.exports = step = (state, t) ->
  # Get the useful stuff out of the state:
  {nodes, dynamics} = state

  # Find a list of indexes of bodies destroyed between this frame and the last
  destroyed = [i for node, i in nodes when node._destroyed]

  # Remove the destroyed indexes
  for i in destroyed => nodes.splice i, 1

  # If we had to remove stuff, regenerate the list of dynamics
  if destroyed.length > 0
    dynamics = nodes |> filter -> it.data?.player? or it.data?.dynamic?

  # Keep track of the time-deltas between each iteration. We use a moving average to
  # smoothly adjust to slower run times
  dt = t / target
  # if dt > 4 then dt = 4
  ts.shift!
  ts.push dt
  dt = mean ts

  # We only need to process physics stuff for dynamic stuff: things that can move
  for obj in dynamics when not obj.frozen

    # Calculate a change in position using speed and time. ∆s = v · ∆t
    v = {
      x: obj.v.x * dt
      y: obj.v.y * dt
    }

    obj <<< {
      last-v: new Vector obj.v
      last-state: obj.state
      last-fall-dist: obj.fall-dist
    }

    obj.p.add-eq v

    obj.aabb = get-aabb obj

    state = find-state obj, nodes

    # Handle general collisions:
    contacts = obj.contacts
    for contact in contacts when contact.sensor is false
      switch
      | contact.type is 'circle'
        'none'

      | contact.type is 'rect' and contact.rotation is 0
        p = obj.aabb
        c = contact.aabb

        # Vertical collision
        on-top-of-thing = false
        if (p.bottom >= c.top and p.top <= c.bottom) then
          if obj.p.y < contact.p.y
            y-ofs = (c.top - obj.height / 2) - obj.p.y
            on-top-of-thing = true
          else
            y-ofs = (c.bottom + obj.height / 2 + pad) - obj.p.y

        # Horizontal collision
        if (p.right >= c.left and p.left <= c.right) then
          if obj.p.x < contact.p.x
            x-ofs = (c.left - obj.width / 2 - pad) - obj.p.x
          else
            x-ofs = (c.right + obj.width / 2 + pad) - obj.p.x

        if x-ofs? and y-ofs?
          if (Math.abs x-ofs) > (Math.abs y-ofs)
            obj.p.y += y-ofs
            obj.v.y = 0

            # Is the obj on top of the thing?
            if on-top-of-thing
              obj.state = 'on-thing'

          else
            obj.p.x += x-ofs
            obj.v.x = 0

        else if x-ofs?
          obj.p.x += x-ofs
          obj.v.x = 0
        else if y-ofs?
          obj.p.y += y-ofs
          obj.v.y = 0

          # Is the obj on top of the thing?
          if on-top-of-thing
            obj.state = 'on-thing'

      | contact.type is 'rect' and contact.rotation isnt 0
        collide = false
        for point in obj.poly when point.in-poly contact.poly
          collide := true
          break

        unless collide
          for point in contact.poly when point.in-poly obj.poly
            collide := true
            break

        if collide
          obj.el.style.background = "rgb(#{255 * Math.random!}, #{255 * Math.random!}, #{255 * Math.random!})"

    if obj.v.y > 0
      obj.fall-dist = obj.p.y - obj.fall-start
    else
      obj.fall-start = obj.p.y

    switch obj.state
    | 'falling', 'contact', 'jumping' =>
      if obj.v.y >= max-fall-speed
        obj.v.y = max-fall-speed
      else
        obj.v.y += fall-acc * dt

      if obj.handle-input then handle-input obj, dt

    | 'on-thing' =>
      # obj.v.y = 0
      # obj.p.y = state.thing.aabb.top - obj.height / 2
      if obj.handle-input then handle-input obj, dt
      obj.fall-dist = 0

    | otherwise =>
      throw new Error 'Unknown state'


    update-el obj

  {nodes, dynamics}

# Manage user input on a player:
handle-input = (node, scale) ->
  # Moving right:
  if keys.right
    # If the object is on a thing, move with standard acceleration. If not, move with in-air acceleration
    node.v.x += if node.state is 'on-thing'
      if node.v.x > 0
        move-acc * scale
      else
        move-damp * scale
    else
      move-acc-in-air * scale

    # Constrain speed
    if node.v.x >= max-move-speed
      node.v.x = max-move-speed

  # Moving left. Same as moving right, but the other way
  else if keys.left
    node.v.x -= if node.state is 'on-thing'
      if node.v.x < 0
        move-acc * scale
      else
        move-damp * scale
    else
      move-acc-in-air * scale

    if node.v.x <= - max-move-speed
      node.v.x = - max-move-speed

  # Not moving.
  else
    # If the object is moving right:
    if node.v.x > 0
      # Slow it down. The rate depends on if it's on the ground or not
      node.v.x -= if node.state is 'on-thing' then move-damp else move-damp-in-air

      # If it slows down so much it starts going the other way, stop it
      if node.v.x < 0 then node.v.x = 0

    # Repeat for moving left:
    else if node.v.x < 0
      node.v.x += if node.state is 'on-thing' then move-damp else move-damp-in-air
      if node.v.x > 0 then node.v.x = 0

  # Jumping:
  # jump-frames is a timer that counts a the number of frames the player can be
  # accelerating for.
  # jump-state indicates the state of the jump
  #
  # If the jump key is pressed and (the player is on the ground or mid-jump):
  {jump-state, state, jump-frames} = node
  if keys.jump and jump-state is \ready and state is \on-thing
    node.v.y = -jump-speed
    node.jump-frames = max-jump-frames
    node.jump-state = \jumping
    node.fall-dist = 0

  else if keys.jump and jump-state is \jumping and state in <[jumping contact]> and jump-frames > 0
    node.v.y = -jump-speed
    node.jump-frames -= scale
    node.jump-state = \jumping
    node.fall-dist = 0

  else if keys.jump and jump-frames <= 0
    node.jump-state = \stop

  else
    node.jump-state = \ready
