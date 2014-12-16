require! 'memory/object-pool'
# aabb: Axis Aligned Bounding Box. E.G:
#
# This:
#        /\
#       /  \
#      /    \
#      \    /
#       \  /
#        \/
#
# Has an AABB like this:
#      ______
#     |  /\  |
#     | /  \ |
#     |/    \|
#     |\    /|
#     | \  / |
#     |__\/__|
#
# We use AABBs in collision detection because it is very fast to check if two of them intersect.
# This means we can rule out collisions between two shapes that are miles away from each other
# very quickly, and then move on to more advanced and slower techniques for seeing if two thins
# are actually colliding.

# Get AABB takes an object and returns the aabb for it.
get-aabb = (obj) ->
  {x, y} = obj.p
  {width, height, radius, sint, cost} = obj

  switch
  # A rectangle with no rotation is its own bounding box. Easy!
  | obj.type is 'rect' and obj.rotation is 0
    object-pool.alloc! <<< {
      left: x - width / 2
      right: x + width / 2
      top: y - height / 2
      bottom: y + height / 2
    }

  # Finding the aabb of a rotated rectangle is a little trickier. See http://i.stack.imgur.com/0SH6d.png
  | obj.type is 'rect' and obj.rotation isnt 0
    aabb-width = height * sint + width * cost
    aabb-height = width * sint + height * cost

    # ALLOC
    {
      left: x - aabb-width / 2
      right: x + aabb-width / 2
      top: y - aabb-height / 2
      bottom: y + aabb-height / 2
    }

  # A circle's aabb is the same regardless of rotation
  | obj.type is 'circle'
    # ALLOC
    {
      left: x - radius
      right: x + radius
      top: y - radius
      bottom: y + radius
    }

# find-bbox-intersects takes two nodes, and returns true if their aabbs intersect, false in not.
find-bbox-intersects = (shape-a, shape-b) -->
  # If the shapes are the same, ignore
  if shape-a is shape-b then return false

  a = shape-a.aabb
  b = shape-b.aabb

  # Simple bounding box test (separating axis theorem)
  not (
    b.left > a.right or
    b.top > a.bottom or
    b.bottom < a.top or
    b.right < a.left
  )

# Get a list of potential contacts between one node and a list of nodes
get-contacts = (node, nodes) ->
  # Currently, this is a very naive implementation
  # ALLOC
  filter (find-bbox-intersects node), nodes

module.exports = { get-aabb, find-bbox-intersects, get-contacts }
