export class Klass {
  function method() {
    return "hello";
  }

  function method2( arg1, arg2 ) {

  }
}

class Klass2 extends Klass {

}


var obj  = new Klass();
var obj2 = new Klass2();

$m.test(#(assert){
  assert.eq("hello", obj.method());
  assert.eq("hello", obj2.method());
});


