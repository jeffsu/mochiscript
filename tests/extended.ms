var extended = null;
class Foo {
  static function extended(klass) {
    extended = klass; 
  }
}

class Bar extends Foo {

}

$m.test(#{ $1.eq(Bar, extended) });
