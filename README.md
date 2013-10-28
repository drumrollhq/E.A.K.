Erase All Kittens
=================

Erase All Kittens is a new open source game about an evil rebellion, intent on destroying all kittens on the Internet. Learn to code whilst playing to help save the kittens, and consequently save the world! We have an *early* demo you can play at http://eraseallkittens.com/

We’re a team of one developer, one creative and one designer who are trying to teach kids to code with the best game we can build. We’ve created the story, structure and look of the game, and we’d like some help to develop it further, specifically from developers, illustrators, and level designers.

If you’re interested in what we’ve done so far or would like to help out, we’d love to hear from you. Fill out the form on [our website](http://eraseallkittens.com/), and we'll get in touch :) 

Contributing
------------

Todo

Getting set up with the code
----------------------------

Todo

Structure
---------
EAK is very loosely based around Backbone, mainly for its event system. `app/scripts/game/mediator` is a global event module, that also manages frames, key events, and notifications. Events from the mediator are partially documented below.

Most of the code is in `app/scripts/game`. `app/scripts` contains a few utilities and `Init`, the module that starts up the Game. `app/scripts/WebWorker` provides a layer of abstraction over Web Workers (worker modules are in `app/workers`). `app/game/dom/mapper` is a utility that carefully maps elements in the dom to be fed into the physics engine.

There are a few unit tests in `test` - don't worry about these. They are unmaintained, and cover only a small fraction of the code. If you'd like to clean them up and add more extensive tests, that'd be cool, but it's not something I really have time for at the moment.

Mediator Events
---------------
- `frame:process` - this is triggered either 60 or 30 times a second. Any non-render tasks to be run every frame (e.g. physics)
- `frame:render` - render tasks to be run every frame
- `frame` - same as `frame:process`
- `alert` - triggering an alert causes a notification to be shown on screen.
- `resize` - window resize events
- `tilt` - abstracted device orientation events. Currently disabled.
- `uncaughtTap` - triggered when the screen is tapped / clicked but the event is not caught elsewhere
- `keypress:[keylist]`, `keyup:[keylist]`, `keydown[keylist]` - document key events for the corresponding handlers, where keylist is a comma-separated list of keys - e.g. `keydown:w,up,space` is used for making the player jump
