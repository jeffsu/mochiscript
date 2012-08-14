
var funct = #{  };
var hash = {
  funct: #{ },
  foo: 'bar'
};

var hash2 = {
  foo: 'bar',
  funct: #{ }
};

var hello = ##{ return "hello" };

$m.test(#{ 
  $1.eq(hello, 'hello');
});
