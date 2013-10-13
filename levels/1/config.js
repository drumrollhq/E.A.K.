{
  "name": "Moving About",
  "width": "640",
  "height": "480",
  "borders": "all",
  "player": {
    "x": -230,
    "y": -50
  },
  "target": "<img src=\"{{base}}/level1/kitten-1.gif\" data-dynamic style=\"position: absolute; right: 15px; top: 150px; width: 150px;\">",
  "hints": [
    {
      "type": "pointer",
      "target": ".player",
      "content": "This is you! You can move left and right with the <kbd>A</kbd> and <kbd>D</kbd>, or <kbd>←</kbd> and <kbd>→</kbd> keys.",
      "enter": "time:1",
      "exit": "keydown:left,right,a,d",
      "exitDelay": 0.5,
      "name": "leftright"
    },
    {
      "type": "pointer",
      "target": ".intheway",
      "content": "Jump using the <kbd>W</kbd>, <kbd>space</kbd>, or <kbd>↑</kbd> keys. You might need a run up to get over this obstacle!",
      "enter": "hint-leftright:exit",
      "exit": "keydown:up,space,w",
      "name": "jump"
    },
    {
      "type": "pointer",
      "target": "[data-target]",
      "content": "Get to the kitten gif to complete the level!",
      "enter": "hint-jump:exit",
      "exit": "beginContact:ENTITY_PLAYER&ENTITY_TARGET"
    }
  ]
}
