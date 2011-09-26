class TestClass {
  static var foo = "foobar";

  static function testMethod() {
    return "hello";
  }
}

$m.test(#{
  $1.eq("hello", TestClass.testMethod());
  $1.eq("foobar", TestClass.foo);
});
