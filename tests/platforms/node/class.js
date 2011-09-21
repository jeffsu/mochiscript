var $m = require("../../../js/platforms/node.js").mochi;
console.log($m.parse("class Foo { var hello = yay; function hello() { } private { var foo = 'bar'; } }"));
console.log($m.parse("var foo = 'bar';"));

