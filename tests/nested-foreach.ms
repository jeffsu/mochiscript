var array = [ [ 'hello', 'world' ], [ 'world', 'hello' ] ];

var counter = 0;
foreach (var a in array) {
  foreach (var b in a) {
    counter++;
  }
}

$m.test(#{ $1.eq(counter, 4) });
