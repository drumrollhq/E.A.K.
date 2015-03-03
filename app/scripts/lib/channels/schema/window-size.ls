module.exports = {
  name: \window-size
  schema:
    width: {type: \number, +required}
    height: {type: \number, +required}
  default-value:
    width: $ document.body .width!
    height: $ document.body .height!
}
