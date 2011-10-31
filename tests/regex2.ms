class Hello {
  function foo() {
    var foo = "hello?";
    foo.replace(/\?/, '');

    return {
      foo     : foo,
      queryString : replace(/abc/, '')
    };
  }

  function bar () {
    return 'bar';
  }
}

var hello = new Hello();
hello.bar();
