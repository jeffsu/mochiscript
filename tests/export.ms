if ($m.PLATFORM == 'node') {
  export class Foo {

  }

  public class Bar {

  }

  $m.test(#(assert){
    assert.isTrue(module.exports); 
    assert.isTrue(exports.Bar); 
  });
}
