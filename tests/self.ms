class TestSelf {
  var foo = "bar";

  function hello() {
    return self.foo;  
  }
}

$m.test(#(assert) {
  var test = new TestSelf();
  assert.eq(test.hello(), test.foo);
});
