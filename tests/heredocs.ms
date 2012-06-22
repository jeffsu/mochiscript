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

$m.test(#{
  $1.eq("hello\nworld", test1);
  $1.eq("hello\nworld", test2);
  $1.eq("hello world", test4);
});
