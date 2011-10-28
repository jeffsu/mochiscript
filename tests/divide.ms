// this is a test for a common javascript divide parsing bug
var stuff = 40;
var foo   = stuff / 10;

var test  = 4 / 2;
var regex = /hello/;

$m.test(#{
  $1.eq(2, test);
  $1.isTrue("hello".match(regex));
});
