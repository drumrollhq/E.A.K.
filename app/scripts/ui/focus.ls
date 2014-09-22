$el = $ '''
  <div class="focus-overlay focus-overlay-top"></div>
  <div class="focus-overlay focus-overlay-bottom"></div>
  <div class="focus-overlay focus-overlay-left"></div>
  <div class="focus-overlay focus-overlay-right"></div>
'''

$el.append-to document.body
$top = $el.filter '.focus-overlay-top'
  ..css top: 0, left: 0, right: 0

$bottom = $el.filter '.focus-overlay-bottom'
  ..css bottom: 0, left: 0, right: 0

$left = $el.filter '.focus-overlay-left'
  ..css left: 0

$right = $el.filter '.focus-overlay-right'
  ..css right: 0

module.exports = {
  focus: (target) ->
    console.log 'focus'
    rect = target.get-bounding-client-rect!
    $el.add-class 'active' .remove-class 'inactive'
    $top.css height: rect.top
    $bottom.css top: rect.bottom
    $left.css top: rect.top, height: rect.height, width: rect.left
    $right.css top: rect.top, height: rect.height, left: rect.right

  blur: ->
    console.log 'blur'
    $el
      ..remove-class 'active'
      ..add-class 'inactive'
      ..one animation-end, -> $el.remove-class 'inactive'
}
