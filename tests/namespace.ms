class Namespace.Klass {
  function method() {
    return "hello";
  }
}

class Namespace.Namespace2.Klass {
  function method() {
    return "hello";
  }
}

var obj  = new Namespace.Klass();
var obj2 = new Namespace.Namespace2.Klass();

$m.test(#(assert) {
  assert.eq("hello", obj.method());
  assert.eq("hello", obj2.method());
});
