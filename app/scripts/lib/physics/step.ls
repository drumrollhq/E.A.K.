require! {
  'lib/channels'
  'lib/math/Matrix'
  'lib/math/Vector'
  'lib/physics/collision'
}

const max-fall-speed = 10px,
  fall-acc = 0.3px,
  pad = 0.1

old-els = []
trails = false

update-el = (obj) ->
  if obj.draw then return obj.draw!

  t = "translate3d(#{obj.p.x - obj.x}px, #{obj.p.y - obj.y}px, 0)"
  if obj._lt is t then return

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

put-on-thing = (obj, thing) ->
  obj.state = 'on-thing'
  if thing.data?.dynamic? or thing.data?.actor?
    obj.fixed-to = {
      target: thing
      pos: thing.p .minus obj.p
      target-pos: new Vector thing.p
    }

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
    dynamics = nodes |> filter -> it.data?.dynamic? or it.data?.actor?

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

    if obj.fixed-to
      fixed-target = obj.fixed-to.target
      if (obj.fixed-to.target-pos .dist-sq fixed-target.p) < 250
        obj.p <<< fixed-target.p .minus obj.fixed-to.pos .{x, y}
        target-y = fixed-target.aabb.top - obj.height / 2
        obj.p.y = target-y if (Math.abs target-y - obj.p.y) < 20
      obj.fixed-to = null

    obj.p.add-eq v

    obj.aabb = get-aabb obj

    state = find-state obj, nodes

    # Handle general collisions:
    unless obj.data.ignore-others
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
              if y-ofs <= 0 then on-top-of-thing = true

            else
              obj.p.x += x-ofs
              obj.v.x = 0

          else if x-ofs?
            obj.p.x += x-ofs
            obj.v.x = 0
          else if y-ofs?
            obj.p.y += y-ofs
            obj.v.y = 0
            if y-ofs <= 0 then on-top-of-thing = true

          # Is the obj on top of the thing?
          if on-top-of-thing => put-on-thing obj, contact

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
      if obj.data.use-gravity
        if obj.v.y >= max-fall-speed
          obj.v.y = max-fall-speed
        else
          obj.v.y += fall-acc * dt

      if obj.step then obj.step dt

    | 'on-thing' =>
      # obj.v.y = 0
      # obj.p.y = state.thing.aabb.top - obj.height / 2
      if obj.step then obj.step dt
      obj.fall-dist = 0

    | otherwise =>
      throw new Error 'Unknown state'


    update-el obj

  {nodes, dynamics}
