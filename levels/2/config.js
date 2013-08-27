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
  "background": "white url(//s3-eu-west-1.amazonaws.com/somehats/web-platformer/grid.png) center center / 50px",
  "player": {
    "x": -440,
    "y": -70
  },
  "assets": [
    "level2/kitten-2.gif",
    "terminal.png"
  ],
  "target": "<img src=\"https://s3-eu-west-1.amazonaws.com/somehats/web-platformer/level2/kitten-2.gif\" style=\"position: absolute; top: 30px; right: 30px;\" data-dynamic>",
  "hints": [
    {
      "type": "pointer",
      "target": ".ledge.right",
      "content": "Try to jump over to this ledge",
      "enter": "time:1",
      "exit": "falloutofworld",
      "name": "oops"
    },
    {
      "type": "pointer",
      "target": ".edit",
      "content": "Uh oh! You need to make the ledge longer. Click 'Edit' or press the <kbd>E</kbd> key to modify the level.",
      "enter": "hint-oops:exit",
      "exit": "edit"
    },
    {
      "type": "pointer",
      "target": "#editor",
      "content": "This is the edit view. The code represents this level. If you change the code, the level is changed too. <a href=\"event:closeEditHint\">Next →</a>",
      "enter": "edit",
      "enterDelay": 0.4,
      "exit": "closeEditHint",
      "side": true
    },
    {
      "type": "pointer",
      "target": ".save",
      "content": "When you're finished editing, press save to go back to the level. Reset will get rid of any changes you've made, and Cancel will both get rid of your changes and take you back to the level. <a href=\"event:closeSaveHint\">Got it →</a>",
      "enter": "closeEditHint",
      "enterDelay": 0.3,
      "exit": "closeSaveHint"
    },
    {
      "type": "pointer",
      "target": ".CodeMirror-code > :first-child .CodeMirror-linewidget",
      "content": "This is a comment. It's not part of your code, but it can help you to understand it better. <a href=\"event:closeCommentHint\">Ok →</a>",
      "enter": "closeSaveHint",
      "enterDelay": 0.3,
      "exit": "closeCommentHint",
      "side": true
    },
    {
      "type": "pointer",
      "target": ".CodeMirror-code > :nth-child(2)",
      "content": "This line is the code for the ledge you are on. If you edit the stuff between <code>&lt;p ...&gt;</code> and &lt;/p&gt;, you should be able to make the ledge long enough to cross the gap. <a href=\"event:closeLineHint\">Great →</a>",
      "enter": "closeCommentHint",
      "enterDelay": 0.3,
      "exit": "closeLineHint"
    }
  ]
}