// Prelude-ls sets require, which breaks everything. This fixes that.
window.preludeLs = require('prelude-ls');
delete window.require
