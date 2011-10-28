module TestModule {
  function foo() {
    return "hello";
  }
}

class TestClass {
  include TestModule;
}

var obj = new TestClass();

$m.test(#{
  $1.eq('hello', obj.foo());
});

var module = {};
module.foo = "bar";
