require! {
  './Vector'
  './Matrix'
  './prepare'
  './step'
  './collisions'
}

/*

A modular physics library for use with maps from game/dom/mapper.

Usage:

  map = get-map-from-mapper!

  // state represents the entire physics world
  state = prepare map

  every frame:
    // Update runs the physics simulations to get to the next frame. time-delta should be the
    // number of milliseconds elapsed since the last frame
    state = update state, time-delta


*/

module.exports = { Vector, Matrix, prepare, step, collisions }

module.exports = physics = (nodes) ->
  console.log nodes

  nodes = nodes |> map ->
    it.v = new Vector 0, 0
    it.p = new Vector it.{x, y}
    it.jump-frames = 0
    it.sin = sint = sin it.rotation
    it.cos = cost = cos it.rotation
    it.matrix = matrix = new Matrix cost, sint, -sint, cost
    # Find polygon:
    if it.type is 'rect'
      {width, height, x, y} = it
      hw = width / 2
      hh = height / 2
      it.poly = [
        new Vector x - hw, y - hh
        new Vector x + hw, y - hh
        new Vector x + hw, y + hh
        new Vector x - hw, y + hh
      ]

      # If rotated:
      if it.rotation isnt 0
        it.poly = for point in it.poly
          # center on origin:
          c = point `vmin` it.p

          # Apply rotation matrix, transform back
          (matrix.transform c) `vadd` it.p

    it

  player = nodes |> filter ( .data.player?) |> head
  dynamics = nodes |> filter ( -> it.data.player? or it.data.dynamic? )
  nodes = nodes |> filter ( -> not it.data.player? )

  player.is-player = true

  player.handle-input = (scale) ->
    if keys.right
      player.v.x += if player.state is 'on-thing' then move-acc * scale else move-acc-in-air * scale
      if player.v.x >= max-move-speed
        player.v.x = max-move-speed

    else if keys.left
      player.v.x -= if player.state is 'on-thing' then move-acc * scale else move-acc-in-air * scale
      if player.v.x <= - max-move-speed
        player.v.x = - max-move-speed

    else
      if player.v.x > 0
        player.v.x -= if player.state is 'on-thing' then move-damp else move-damp-in-air
        if player.v.x < 0 then player.v.x = 0
      else if player.v.x < 0
        player.v.x += if player.state is 'on-thing' then move-damp else move-damp-in-air
        if player.v.x > 0 then player.v.x = 0

    if (keys.jump) and (player.state is 'on-thing' or player.jump-frames > 0)
      player.v.y = - jump-speed
      if player.jump-frames <= 0 then player.jump-frames = max-jump-frames
      player.jump-frames--
    else if keys.jump is false and player.jump-frames > 0
      player.v.y = player.v.y / 2
      player.jump-frames = -1
    else if keys.jump and player.jump-frames is 0
      player.v.y = player.v.y / 2
      player.jump-frames = -1
    else
      player.jump-frames = -1

  update-el = (obj) ->
    obj.el.style.transform = obj.el.style.moz-transform = obj.el.style.webkit-transform = "translate(#{obj.p.x - obj.x}px, #{obj.p.y - obj.y}px)"

  get-aabb = (obj) ->
    | obj.type is 'rect' and obj.rotation is 0
      {
        left: obj.p.x - obj.width / 2
        right: obj.p.x + obj.width / 2
        top: obj.p.y - obj.height / 2
        bottom: obj.p.y + obj.height / 2
      }

    | obj.type is 'rect' and obj.rotation isnt 0
      obj.aabb


    | obj.type is 'circle'
      {
        left: obj.p.x - obj.radius
        right: obj.p.x + obj.radius
        top: obj.p.y - obj.radius
        bottom: obj.p.y + obj.radius
      }

  find-bbox-intersects = (shape-a, shape-b) -->
    if shape-a === shape-b then return false

    a = shape-a.aabb
    b = shape-b.aabb

    not (
      b.left > a.right or
      b.top > a.bottom or
      b.bottom < a.top or
      b.right < a.left
    )

  is-contact-above = (shape-a, shape-b) --> true
    # shape-a.p.y >= shape-b.y

  get-contacts = (obj, nodes) -> filter (find-bbox-intersects obj), nodes

  find-state = (obj) ->
    contacts = get-contacts obj, nodes

    obj.contacts = contacts

    # Find contacts we appear to be on top of (naive)
    above-contacts = filter (is-contact-above obj), contacts

    if above-contacts.length
      contact = head above-contacts
      obj.state = 'contact'
      return {
        type: 'contact'
        thing: contact
      }

    obj.state = 'falling'

    {type: 'falling'}

  target = 1000 / 60 # Aim for 60fps

  ts = replicate 300 1

  update = (t) ->

    dt = t / target
    if dt > 4 then dt = 4
    ts.shift!
    ts.push dt
    dt = mean ts

    for obj in dynamics

      v = {
        x: obj.v.x * dt
        y: obj.v.y * dt
      }

      obj.p.add v

      obj.aabb = get-aabb obj

      state = find-state obj

      # Handle general collisions:
      contacts = obj.contacts
      for contact in contacts => switch
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
              obj.jump-frames = -1

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
            obj.jump-frames = -1

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

      switch obj.state
      | 'falling', 'contact' =>
        if obj.v.y >= max-fall-speed
          obj.v.y = max-fall-speed
        else
          obj.v.y += fall-acc

        if obj.is-player then obj.handle-input dt

      | 'on-thing' =>
        # obj.v.y = 0
        # obj.p.y = state.thing.aabb.top - obj.height / 2
        if obj.is-player then obj.handle-input dt

      | otherwise =>
        throw new Error 'Unknown state'


      update-el obj
