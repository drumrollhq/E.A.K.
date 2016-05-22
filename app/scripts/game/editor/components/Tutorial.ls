dom = React.DOM
{CSSTransitionGroup} = React.addons

auto-key = (nodes, id = \auto-key) ->
  | typeof! nodes is \Array => nodes.map (node, i) -> auto-key node, "#id.#i"
  | otherwise => dom.span key: id, nodes

module.exports = React.create-class {
  display-name: \Tutorial
  mixins: [Backbone.React.Component.mixin]

  render: ->
    {msg, options = {}, id} = @state.model.msg or {}
    options = {
      top: '40vh'
      left: '100px'
    } <<< options

    style = "#{prefixed.transform}": "translate(#{options.left}, #{options.top})"

    console.log \tutorial-speech-msg-render, msg, auto-key msg

    dom.div class-name: \tutorial-overlay,
      React.create-element CSSTransitionGroup, {
        transition-name: \fade
        transition-enter-timeout: 300ms
        transition-leave-timeout: 300ms
      },
        if msg
          dom.div class-name: \tutorial-speech, style: style, key: \speech,
            dom.img class-name: \tutorial-speech-img, src: "/content/common/#{@state.model.tutor}.png"
            React.create-element CSSTransitionGroup, {
              transition-name: \fade
              transition-enter-timeout: 300ms
              transition-leave-timeout: 300ms
            },
              dom.div class-name: \tutorial-speech-msg, key: id, auto-key msg
}
