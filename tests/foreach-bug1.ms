
var foo = { hello: #{ => [ 1, 2, 3 ] } };
var val = null;

foreach (var i in foo.hello()) val = i;

$m.test(#{ $1.eq(val, 3) });
