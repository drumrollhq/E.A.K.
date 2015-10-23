require! {
  'assets'
}

dom = React.DOM
{CSSTransitionGroup} = React.addons

module.exports = React.create-class {
  display-name: \Speaker
  render: ->
    side = @props.position or \left
    key = "#{@props.character}-#{@props.expression}-#{@props.background}"
    img = assets.load-asset "/content/conversation/#{@props.character}/#{side}/#{@props.expression}.png" \url
    if @props.background
      background = assets.load-asset "/content/conversation/#{@props.character}/#{side}/#{@props.background}.png" \url

    main = dom.img key: \img, src: img
    content = if background
      [(dom.img key: \bg, src: background), main]
    else main

    React.create-element CSSTransitionGroup, {
      transition-name: \conversation-speaker
      class-name: "conversation-speaker conversation-speaker-#{@props.position}"
      component: \div
    }, dom.div key: key, content
}
