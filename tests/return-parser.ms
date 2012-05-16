var array = [ 1, 2 ].map(#{ => $1 + 2; });
$m.test(#(assert) {
  assert.eq(3, array[0]);
});
