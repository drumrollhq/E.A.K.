dom = React.DOM

module.exports = React.createClass {
  display-name: \TutorialComponent
  mixins: [Backbone.React.Component.mixin]
  render: ->
    dom.div null, 'Hello, world'
}
