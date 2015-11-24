# Defining E.A.K. Editor Tutorials

E.A.K. editor tutorials are defined with the Tutorial DSL, in [/app/scripts/game/tutorial/Tutorial.md]().

# Editor Selectors
Selectors in this document refer to CSS selectors. However, when the selectors are being used to
select code in the editor, a number of additional pseudo selectors are available:

* No pseudo selector - select the whole element: **&lt;p class="yo"&gt; Hello! &lt;/p&gt;**
* `::inner` - select the contents of the element: &lt;p class="yo"&gt; **Hello!** &lt;/p&gt;
* `::outer` - select the opening and closing tags of the element: **&lt;p class="yo"&gt;** Hello! **&lt;/p&gt;**
* `::open` - select the opening tag: **&lt;p class="yo"&gt;** Hello! &lt;/p&gt;
* `::close` - select the closing tag: &lt;p class="yo"&gt; Hello! **&lt;/p&gt;**

# Tutorial definition methods:

## step(id)
```lsc
tutorial
  .step \my-step
    .say \line 'Say a thing!'
  .end \step
```

This method creates a new step within a tutorial. Steps cannot be defined within
other steps.

## end(type)
End the current context: step, branch of a conditional, etc. Supplying types mean this will only succeed if
the current context type is one of the listed types.

```lsc
tutorial
  .step \meow # Start a step
    # ...
  .end \step # End a step, ready for the next one

  .step \woof
    # ...
  .end! # End the current context - in this case a step

  .step \baa
    # ...
  .end \branch # Throws error - can't end 'branch' when current context is 'step'
```

## target(id, goal, options = {wait: false, condition})
```lsc
tutorial
  .target \be-tall, 'Grow to be over 100px tall' do
    condition: -> arca.height > 100
```

Create a target to be achieved - `condition` is a function that evaluates to true
when the target has been met. If `wait` is true, the tutorial system will wait
until the target has been met before evaluating the next item on the AST.

## say(track, options = {async: false, interruptible: false, target, target-code, focus: false}, lines)
Have the tutor say a line within a step. `track` and `lines` are neeeded, options are optional.
`line` can either be a simple string, or an object cueing certain bits of text at certain times:

```lsc
.say \some-line do
  0: "Started"
  1: "Shows up 1 second in"
  3: "Shows up 3 seconds in"
```

Options:
* `async` - if true, the interpreter will start saying the lines, but immediately execute the next
    instruction.
* `interruptible` - if true, the lines will stop if they get to the end of a step but haven't
    finished playing. Useful when combined with `async: true`, and waiting for other events:
    ```lsc
    tutorial
      .step \step
        .say \some-line async: true, interruptible: true, 'Change something to interrupt me!'
        .await-event 'change'
      .end!
    ```

## wait(timeout)
Waits `timeout` milliseconds before moving on to the next instruction.

## await-select(selector)
Block execution until the users cursor in the editor is on text matching `selector`.

## await-event(name)
Block execution until the next time the editor fires an event of `name`.

## tutor(name)
Set the tutor to name - used for displaying tutor image

## lock(selector)
Make code in the editor matching `selector` read-only. If no selector is supplied,
the entire editor is made read-only.

## unlock(selector)
Like `lock`, but marks code as editable rather than read-only.

## highlight-code(selector)
Highlights code in the editor matching `selector`.

## highlight-level(selector)
Highlights elements in the level matching `selector`.

## clear-highlight()
Clears any active highlights. This is done automatically at the end of a step.

## save()
Presses the editor 'Save' button.

## reset()
Presses the editor 'Reset' button.

## cancal()
Presses the editor 'Cancel' button.
