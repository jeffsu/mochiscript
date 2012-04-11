class Foo {
  private {
    var data = [ [ 1, 2 ] ];
  }

  function bar2() {
    return data.map(#(row) { => row[0] ? row[1] / row[0] : null });
  }


  function bar() {
    return data.map(#(row) { => row[0] ? row[1] / row[0] : null });
  }

  function foo() {
    return "foo";
  }
}

// basically, don't crash
$m.test(#(assert) { 
  var foo = new Foo();
  foo.bar2();
  foo.bar();
  foo.foo();
});
