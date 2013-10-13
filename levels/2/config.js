{
  "name": "Editing Text",
  "width": "1000",
  "height": "380",
  "borders": {
    "top": true,
    "left": true,
    "bottom": false,
    "right": true
  },
  "background": "white url(/content/level2/bg.png) center center / 1000px 380px",
  "player": {
    "x": -440,
    "y": -70
  },
  "target": "<img src=\"{{base}}/level2/kitten-2.gif\" style=\"position: absolute; top: 30px; right: 30px;\" data-dynamic>",
  "hints": [
    {
      "type": "pointer",
      "target": ".ledge.right",
      "content": "Try to jump over to this ledge",
      "enter": "time:1",
      "exit": "falloutofworld edit",
      "name": "oops"
    },
    {
      "type": "pointer",
      "target": ".edit",
      "content": "Uh oh! You need to make the ledge longer. Click 'Edit' or press the <kbd>E</kbd> key to modify the level.",
      "enter": "falloutofworld",
      "exit": "edit"
    }
  ]
}
