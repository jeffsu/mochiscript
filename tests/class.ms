class Klass {
  function method() {
    return "hello";
  }
}

var obj = new Klass();

$m.test(#(assert){
  assert.eq("hello", obj.method());
});
