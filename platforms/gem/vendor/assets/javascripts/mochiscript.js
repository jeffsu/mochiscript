(function (window) {
var $m  = {
  ROOT: window,
  ADAPTER: {
    out:  console.log,
    outs: console.log,
  },
  PLATFORM: 'browser'
};

window.$m = $m;

// CLASS HELPERS
(function (undefined, $m) {

  var OO = function (klass, par) {
    this.klass = klass;
    this.par   = par;

    this.members       = {};
    this.staticMembers = {};
    this.children = [];
    this.included = [];

    if (this.par) this.par.OO.children.push(klass);
  };

  $m.PUSH_ROOT = function (r) {
    this.ROOTS = this.ROOTS || [];
    this.ROOTS.push(r);
    this.ROOT = r;
  };

  $m.POP_ROOT = function () {
    this.ROOTS = this.ROOTS || [];
    if (this.ROOTS.length) {
      this.ROOTS.pop();
      this.ROOT = this.ROOTS[this.ROOTS.length-1];
    }

  };

  OO.prototype = {
    forbiddenMembers: {
      'prototype': undefined,
      'OO': undefined
    },

    include: function(module) {
      this.included.push(module);
      var members = module.OO.members;
      for (var name in members) {
        if (members.hasOwnProperty(name)) {
          this.addMember(name, members[name]);
        }
      }

      var staticMembers = module.OO.staticMembers;
      for (var name in staticMembers) {
        if (staticMembers.hasOwnProperty(name)) {
          this.addStaticMember(name, staticMembers[name]);
        }
      }

      if (typeof staticMembers['included'] == 'function') {
        staticMembers['included'](this.klass);
      }
    },

    createNamespace: function(name) {
      var splitted = name.split('.');
      var klassName = splitted.pop();
      var root = $m.ROOT;

      while (splitted.length > 0) {
        var name = splitted.shift();
        if (!root[name]) root[name] = $m.Class.extend({});
        root = root[name];
      }

      return [ root, klassName ];
    },

    makeSuper: function(newMethod, oldMethod) {
      if (!oldMethod) return newMethod;

      return function() {
        this.$super = oldMethod;
        return newMethod.apply(this, arguments);
      };
    },

    addMember: function(name, member) {
      if (this.forbiddenMembers.hasOwnProperty(name)) return;

      var proto = this.klass.prototype;
      if (typeof proto[name] == 'function' && !(proto[name] instanceof RegExp)) {
        member = this.makeSuper(member, proto[name]);
      }

      proto[name] = member;
      this.members[name] = member;
    },

    addStaticMember: function(name, member) {
      if (this.forbiddenMembers.hasOwnProperty(name)) return;

      if (typeof this.klass[name] == 'function') {
        if (!this.klass.hasOwnProperty(name)) {
          member = this.makeSuper(member, this.klass[name]);
        }
      }

      this.klass[name] = member;
      this.staticMembers[name] = member;
    }
  };

  $m.Class = function() { this.initialize.apply(this, arguments); };
  $m.Class.OO = new OO($m.Class);
  $m.Class.prototype = {
    initialize: function () {},
    oo: $m.Class.OO
  };

  var namedClasses = {};
  $m.getClass = function(name) {
    return namedClasses[name];
  };

  var noInit = false;
  $m.Class.extend = function(name, klassDef) {
    var klass = function() { if (!noInit) this.initialize.apply(this, arguments); };
    klass.OO  = new OO(klass, this);

    if (typeof name != 'string') {
      klassDef = name;
    } else {
      namedClasses[name] = klass;
      var namespace = this.OO.createNamespace(name);
      namespace[0][namespace[1]] = klass;
    }

    // create instance of this as prototype for new this
    noInit = true;
    var proto = new this();
    noInit = false;

    klass.prototype = proto;
    var oo   = klass.OO;
    proto.OO = oo;

    for (var name in this) {
      oo.addStaticMember(name, this[name]);
    }

    if (typeof klassDef == 'function') {
      klassDef(klass, oo);
    } else {
      for (var name in klassDef) {
        oo.addMember(name, klassDef[name]);
      }
    }

    return klass;
  };

  $m.Module = $m.Class;

  var assert = {
    'eq': function(expected, actual) { if (expected != actual) $m.outs("Expected "+expected+", but got "+actual+".") },
    'isFalse': function(val) { if (val) $m.outs("Expected false, but got "+JSON.stringify(val)+".") },
    'isTrue': function(val) { if (!val) $m.outs("Expected true, but got " +val+".") }
  };

  $m.test = function(message, callback) {
    if (!callback) callback = message;
    callback(assert);
  };

  function addListener(type, listener) {
    var events = this.__$events || (this.__$events = {});
    this.emit('newListener', type, listener);
    if (!events[type]) events[type] = [];
    events[type].push(listener);
  }

  $m.EventEmitter = $m.Module.extend({
    emit: function () {
      // TODO optimize
      var type     = arguments[0];
      var events   = this.__$events || (this.__$events = {});
      var handlers = events[type];

      if (!handlers) return false;

      var args = [];
      for (var i=1,len=arguments.length; i<len; i++) args[i-1] = arguments[i];
      for (var i=0,len=handlers.length; i<len; i++) handlers[i].apply(this, args);
    },

    addListener: addListener,
    on: addListener
  });

  $m.out = function () {
    for (var i=0,arg=null,_list_0=arguments,_len_0=_list_0.length;(arg=_list_0[i])||i<_len_0;i++){
      $m.ADAPTER.out(arg);
      if (i < arguments.length-1) {
        $m.ADAPTER.out(',');
      }
    }
  };

  $m.outs = function () {
    for (var _i_0=0,arg=null,_list_0=arguments,_len_0=_list_0.length;(arg=_list_0[_i_0])||_i_0<_len_0;_i_0++){
      $m.ADAPTER.outs(arg);
    }
  };

  return $m;
})(undefined, $m);


$m.Class.extend("JSML", function(KLASS, OO){
  OO.addStaticMember("process", function(txt){
    return new $m.JSML(txt);
  });

  OO.addMember("initialize", function(txt){
    var lines = txt.split(/\n/);
    this.root    = new $c.JSMLElement();
    this.stack   = [ this.root ];

    for (var i=0; i<lines.length; i++) {
      var l = lines[i];
      if (l.match(/^\s*$/)) continue;
      this.processLine(l);
    }

    var toEval = 'function stuff() { var out = [];\n' + this.flatten().join('') + '\n return out.join("");\n}';
    eval(toEval);

    this.result = function(bound) {
      bound = bound || {};
      return stuff.call(bound);
    };
  });

  OO.addMember("flatten", function(){
    return this.root.flatten();
  });

  OO.addMember("processLine", function(line){
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
  });


  OO.addMember("getScope", function(){
    return this.stack.length - 1;
  });

  OO.addMember("getLast", function(){
    return this.stack[this.stack.length-1];
  });

});

$m.Class.extend("JSMLElement", function(KLASS, OO){
  OO.addMember("SCOPE_REGEX", /^(\s*)(.*)$/);
  OO.addMember("SPLIT_REGEX", /^((?:\.|\#|\%)[^=\s\{]*)?(\{.*\})?(=|-)?(?:\s*)(.*)$/);
  OO.addMember("TOKEN_REGEX", /(\%|\#|\.)([\w][\w\-]*)/g);
  OO.addMember("JS_REGEX", /^(-|=)(.*)$/g);
  OO.addMember("SCOPE_OFFSET", 1);
  OO.addMember("SELF_CLOSING", { area: null, basefont: null, br: null, hr: null, input: null, img: null, link: null, meta: null });

  OO.addMember("initialize", function(line){
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
  });

  OO.addMember("push", function(child){
    this.children.push(child);
  });

  OO.addMember("parse", function(line){
    this.attributes;
    this.line = line;
    var self = this;

    var splitted = line.match(this.SPLIT_REGEX);
    var tokens   = splitted[1];
    var attrs    = splitted[2];
    var jsType   = splitted[3];
    var content  = splitted[4];

    if (tokens) {
      tokens.replace(this.TOKEN_REGEX, function(match, type, name) {
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
  });

  OO.addMember("flatten", function(){
    var out = [];

    for (var i=0; i<this.children.length; i++) {
      var c = this.children[i];
      var arr = c.flatten();
      for (var j=0; j<arr.length; j++) {
        var item = arr[j];
        out.push(item);
      }
    }

    if (this.nodeType) {
      this.handleJsEQ(out);
      this.handleContent(out);
      out.unshift('out.push("<' + this.nodeType + '"+$m.ROOT.JSMLElement.parseAttributes(' + (this.attributes || "{}") + ', ' + JSON.stringify(this.classes || []) + ', ' + JSON.stringify(this.id || null) + ')+"' + this.selfClose + '>");\n');
      if (this.selfClose == '') {
        out.push('out.push(' + JSON.stringify("</"+(this.nodeType)+">") + ');\n');
      }
    } else {
      this.handleJsExec(out);
      this.handleJsEQ(out);
      this.handleContent(out);
    }

    return out;
  });

  OO.addMember("handleJsEQ", function(out){
    if (this.jsEQ) {
      this.jsEQ = this.jsEQ.replace(/;\s*$/, '');
      out.unshift('out.push(' + this.jsEQ + ');\n');
    }
  });

  OO.addMember("handleContent", function(out){
    if (this.content != null && this.content.length > 0) {
      out.unshift('out.push(' + JSON.stringify(this.content) + ');\n');
    }
  });


  OO.addMember("handleJsExec", function(out){
    if (this.jsExec) {
      out.unshift(this.jsExec);
      if (this.jsExec.match(/\{\s*$/)) {
        out.push("}\n");
      }
    }
  });

  OO.addStaticMember("parseAttributes", function(hash, classes, id){
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
  });
});

$m.JSML = $m.ROOT.JSML;
$m.JSMLElement = $m.ROOT.JSMLElement;


})(window);
