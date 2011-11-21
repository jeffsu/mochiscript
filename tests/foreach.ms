var list = [ 'hello', 'world', 'foo', 'bar', null, {}, false, 'bar2' ];
var container  = null;
var container2 = null;

foreach (var item in list) {
  container = item;
}

foreach (var item:i in list) {
  container2 = i;
}

$m.test(#(assert) {
  assert.eq(container, "bar2");
  assert.eq(container2, 7);
});
