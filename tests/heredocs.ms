// standard
var test1 = <<END;
  hello
  world
END

// interpolated TODO
var test2 = <<END;
  hello
  world
END

var test3 = <<END;
  hello{}=
END

var test4 = <<END + " world";
  hello
END

var foo = {
  test: #{ => $1 + " world" }
};

var test5 = foo.test(<<END);
  hello
END

var test6 = [ 'hello' ].map(#{ => $1 + " " + <<END; })[0];
  world
END

$m.test(#{
  $1.eq("hello\nworld", test1);
  $1.eq("hello\nworld", test2);
  $1.eq("hello world", test4);
  $1.eq("hello world", test5);
  $1.eq("hello world", test5);
  $1.eq("hello world", test6);
});
