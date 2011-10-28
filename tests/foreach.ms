var list = [ 'hello', 'world' ];
var container  = null;
var container2 = null;

foreach (var item in list) {
  container = item;
}

foreach (var item:i in list) {
  container2 = i;
}

$m.test(#(assert) {
  assert.eq(container, "world");
  assert.eq(container2, 1);
});
