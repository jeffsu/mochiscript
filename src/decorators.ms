class Decorator {
  function classToString(klass) {
    var extend = klass.extending || '$m.Class';
    var name   = JSON.stringify(klass.name);
    return extend + ".extend(" + name + "," + 
           "function (KLASS, OO)" +  klass.content.toString()  + ");";
  }
}

class NodeDecorator extends Decorator {
  function classToString(klass) {
    var body = this.$super(klass);
    if (klass.isPublic) {
      return body + "module.exports=" + klass.name + ";";
    } else if (klass.isExports) {
      return body + "module.exports." + klass.name + "=" + klass.name + ";";
    }
  }
}

class BrowserDecorator extends Decorator {

}
