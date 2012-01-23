var foo = [ 'hello', 'world' ];
var foo2 = foo #map { return $1 + '1' } #map { return $1 + '2' };

$m.test(#(assert) {
  assert.eq("hello12", foo2[0]);
});
