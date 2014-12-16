require! 'memory/Pool'

clear-object = (obj) -> for key, _ of obj => delete obj[key]
create-object = -> {}

module.exports = new Pool 'object', create-object, clear-object
