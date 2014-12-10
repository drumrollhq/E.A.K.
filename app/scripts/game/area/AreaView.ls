module.exports = class AreaView extends Backbone.View
  tag-name: 'div'
  class-name: 'area-view'

  render: ->
    @$el.html 'hello!'
    @update-size!
    @update-background!
    $ document.body .add-class \playing

  update-size: ->
    @$el.width @model.get 'width'
    @$el.height @model.get 'height'

  update-background: ->
    @$el.css {
      background-image: "url(#{@model.get 'background'})"
      background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
    }
