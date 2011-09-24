// standard
var test1 = <<END;
  hello
  world
END

// interpolated
var test2 = <<END;
  #{test1}
END

$m.test(#{
  $1.eq("hello\nworld", test1);
  $1.eq("hello\nworld", test2);
});
