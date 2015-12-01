dom = React.DOM
{CSSTransitionGroup} = React.addons

export spinner =
  dom.div class-name: \loading-spinner-player,
    dom.div class-name: \player-inner,
      dom.div class-name: \player-head,
        dom.div class-name: \player-ear-left
        dom.div class-name: \player-ear-right
        dom.div class-name: \player-face
        dom.div class-name: \player-eyes
      dom.div class-name: \player-body
      dom.div class-name: \player-leg-left
      dom.div class-name: \player-leg-right

export toggle = (show-loader, heading, ...child-dom) ->
  if typeof heading is \string
    heading = dom.h4 null, heading
  loader = dom.div null, spinner, heading

  dom.div class-name: (cx \loader-toggle, active: show-loader),
    React.create-element CSSTransitionGroup, {
      transition-name: \loader-toggle
      component: \div
      class-name: \loader-toggle-loader
      transition-enter-timeout: 450ms
      transition-leave-timeout: 300ms
    },
      if show-loader then loader else null
    dom.div class-name: \loader-toggle-contents, ...child-dom
