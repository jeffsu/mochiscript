class Foo {
  include $m.EventEmitter;

}

$m.test(#(assert) {
  var foo = new Foo();
  var bar;
  foo.on('hi', #{ bar = 1 });
  foo.emit('hi');

  assert.eq(bar, 1);
});
