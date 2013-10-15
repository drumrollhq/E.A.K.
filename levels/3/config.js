{
  "name": "Levels are fun!",
  "width": "480",
  "height": "600",
  "borders": {
    "top": true,
    "left": true,
    "bottom": false,
    "right": true
  },
  "player": {
    "x": 130,
    "y": -100
  },
  "assets": [
    "level2/kitten-2.gif",
    "terminal.png"
  ],
  "target": "<img src=\"{{base}}/level3/kitten.gif\" width=\"200\" style=\"position: absolute; top: 30px; left: 30px;\" data-dynamic>",
  "hints": [
    {
      "type": "pointer",
      "target": ".edit",
      "content": "You'll need to edit code to complete most levels. There will usually be hints in the source code to help you, too! Click edit or press <kbd>E</kbd> to change the code.",
      "enter": "time:1",
      "exit": "edit",
      "name": "oops"
    }
  ]
}
