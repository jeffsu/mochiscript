var $m = require('mochiscript').mochi;
var fs = require('fs');
var argv = process.argv;

var file = "./tests/" + argv[argv.length-1];
var str  = fs.readFileSync(file, 'utf8')
console.log($m.parse(str));
