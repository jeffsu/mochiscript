var foo = [ 'hello', 'world' ];
var foo2 = foo #map { $1 + '1' } #map { $1 + '2' };

$m.test(#(assert) {
  assert.eq("hello12", foo2[0]);
});
