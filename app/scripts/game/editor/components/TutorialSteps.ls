dom = React.DOM

module.exports = React.create-class {
  display-name: \TutorialSteps

  mixins: [Backbone.React.Component.mixin]

  render: ->
    i = 0
    dom.ol class-name: \tutorial-steps,
      for let id, step of @state.model.steps
        i += 1
        dom.li {
          class-name: (cx \tutorial-step-btn "step-#{id}-btn")
          on-click: ~> @props.on-click id
          key: id
        }, i
}
