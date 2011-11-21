export class PrivateDemo {
  private {
    var INDEX = 1;
    var NAME  = 'hello';
    var FUN   = function () { return 'foo'; };
  }

  function getINDEX() {
    return INDEX;
  }
  function getNAME() {
    return NAME;
  }
  function getFUN() {
    return FUN;
  }
}

var demo = new PrivateDemo();

$m.test(#(assert){
  assert.eq(1, demo.getINDEX());
  assert.eq('hello', demo.getNAME());
  assert.eq('foo', demo.getFUN()());
});


