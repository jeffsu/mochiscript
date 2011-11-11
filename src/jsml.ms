class JSML {
  static function process(txt) {
    return new $m.JSML(txt);
  }

  function initialize(txt) {
    var lines = txt.split(/\n/);
    this.root    = new $c.JSMLElement();
    this.stack   = [ this.root ];

    foreach (var l in lines) {
      if (l.match(/^\s*$/)) continue;
      this.processLine(l);
    }

    var toEval = 'function stuff() { var out = [];\n' + this.flatten().join('') + '\n return out.join("");\n}';
    eval(toEval);

    this.result = function(bound) {
      bound = bound || {};
      return stuff.call(bound);
    };
  }

  function flatten() {
    return this.root.flatten();
  }

  function processLine(line) {
    if (line.match(/^\s*$/)) return;

    var ele   = new $m.JSMLElement(line);
    var scope = this.getScope();

    if (ele.scope == scope) {
      this.stack.pop();
      this.getLast().push(ele);
      this.stack.push(ele);
    } else if (ele.scope > scope) {
      this.getLast().push(ele);
      this.stack.push(ele);
    } else if (ele.scope < scope) {
      var diff = scope - ele.scope + 1;
      while(diff-- > 0) {
        this.stack.pop();
      }
      this.getLast().push(ele);
      this.stack.push(ele);
    }
  }


  function getScope() {
    return this.stack.length - 1;
  }

  function getLast() {
    return this.stack[this.stack.length-1];
  }

}

class JSMLElement {
  var SCOPE_REGEX  = /^(\s*)(.*)$/;
  var SPLIT_REGEX  = /^((?:\.|\#|\%)[^=\s\{]*)?(\{.*\})?(=|-)?(?:\s*)(.*)$/;
  var TOKEN_REGEX  = /(\%|\#|\.)([\w][\w\-]*)/g;
  var JS_REGEX     = /^(-|=)(.*)$/g;
  var SCOPE_OFFSET = 1;
  var SELF_CLOSING = { area: null, basefont: null, br: null, hr: null, input: null, img: null, link: null, meta: null };

  function initialize(line) {
    this.children = [];

    if (line == null) {
      this.scope = this.SCOPE_OFFSET;
      return;
    }

    var spaceMatch = line.match(this.SCOPE_REGEX);
    this.scope = spaceMatch[1].length / 2 + this.SCOPE_OFFSET;

    this.classes  = [];
    this.nodeID   = null;

    this.parse(spaceMatch[2]);
  }

  function push(child) {
    this.children.push(child);
  }

  function parse(line) {
    this.attributes;
    this.line = line;
    var self = this;

    var splitted = line.match(this.SPLIT_REGEX);
    var tokens   = splitted[1];
    var attrs    = splitted[2];
    var jsType   = splitted[3];
    var content  = splitted[4];

    if (tokens) {
      tokens.replace(this.TOKEN_REGEX, #(match, type, name) {
        switch(type) {
          case '%': self.nodeType = name; break;
          case '.': self.classes.push(name); break;
          case '#': self.nodeID = name; break;
        }
        return '';
      });
    }

    if (jsType == '=') {
      this.jsEQ = content;
    } else if (jsType == '-') {
      this.jsExec = content;
    } else {
      this.content = content;
    }

    if (attrs) {
      this.attributes = attrs;
    }

    if (!this.nodeType && (this.classes.length || this.nodeID)) {
      this.nodeType = 'div';
    }

    if (this.SELF_CLOSING.hasOwnProperty(this.nodeType) && this.children.length == 0) {
      this.selfClose = '/';
    } else {
      this.selfClose = '';
    }
  }

  function flatten() {
    var out = [];

    foreach (var c in this.children) {
      var arr = c.flatten();
      foreach (var item in arr) {
        out.push(item);
      }
    }

    if (this.nodeType) {
      this.handleJsEQ(out);
      this.handleContent(out);
      out.unshift('out.push("<' + this.nodeType + '"+$m.ROOT.JSMLElement.parseAttributes(' + (this.attributes || "{}") + ', ' + JSON.stringify(this.classes || []) + ', ' + JSON.stringify(this.id || null) + ')+"' + this.selfClose + '>");\n');
      if (this.selfClose == '') {
        out.push('out.push(' + JSON.stringify(%{</#{this.nodeType}>}) + ');\n');
      }
    } else {
      this.handleJsExec(out);
      this.handleJsEQ(out);
      this.handleContent(out);
    }

    return out;
  }

  function handleJsEQ(out) {
    if (this.jsEQ) {
      this.jsEQ = this.jsEQ.replace(/;\s*$/, '');
      out.unshift('out.push(' + this.jsEQ + ');\n');
    }
  }

  function handleContent(out) {
    if (this.content != null && this.content.length > 0) {
      out.unshift('out.push(' + JSON.stringify(this.content) + ');\n');
    }
  }


  function handleJsExec(out) {
    if (this.jsExec) {
      out.unshift(this.jsExec);
      if (this.jsExec.match(/\{\s*$/)) {
        out.push("}\n");
      }
    }
  }

  static function parseAttributes(hash, classes, id) {
    var out = [];
    classes = classes || [];
    if (hash['class']) classes.push(hash['class']);
    if (classes.length) hash['class'] = classes.join(" ");

    for (var k in hash) {
      if (hash.hasOwnProperty(k)) {
        out.push(k + '=' + JSON.stringify(hash[k]));
      }
    }
    return (out.length ? ' ' : '') + out.join(' ');
  }
}

$m.JSML = $m.ROOT.JSML;
$m.JSMLElement = $m.ROOT.JSMLElement;
