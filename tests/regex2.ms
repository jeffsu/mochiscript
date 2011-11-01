class Hello {
  function foo() {
    var foo = "hello?";
    foo.replace(  /\?/, '');
    foo.replace(/\?/, '');
    foo.replace(/\?/, '');
    var n = ((10) / foo);

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
