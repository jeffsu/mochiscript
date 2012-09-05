var list = [ 'hello', 'world', 'foo', 'bar', null, {}, false, 'bar2' ];

foreach (var item in list) container = item;

$m.test(#{ $1.eq(container, 'bar2') });
