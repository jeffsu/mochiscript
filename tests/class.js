console.log($m.parse("class Foo { var hello = yay;\n function hello() { } private { var foo = 'bar'; foreach (var foo in bar) { } } }"));
console.log($m.parse("var foo = 'bar';"));
console.log($m.parse("%{hello}"));
console.log($m.parse("%{he#{l}lo}"));
