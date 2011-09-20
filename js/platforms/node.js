var $m  = { ROOT: {} };
var JS2 = $m;

(function () {

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
    'eq': function(expected, actual) { if (expected != actual) console.log("Expected "+expected+", but got "+actual+".") },
    'isFalse': function(val) { if (val) console.log("Expected false, but got "+JSON.stringify(val)+".") },
    'isTrue': function(val) { if (!val) console.log("Expected true, but got " +val+".") }
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

  return $m;
})(undefined, $m);


var IDENT  = "[\\$\\w]+";
var TOKENS = [
  [ "SPACE",        "\\s+"  ],
  [ "CLASS",        "class", 'ClassParser' ], 
  [ "FUNCTION",     "function\\b" ], 
  [ "VAR",          "var\\b" ], 
  [ "STATIC",       "static\\b" ], 
  [ "DSTRING",      "\"(\\\\.|[^\"])*\"" ], 
  [ "SSTRING",      "'(\\\\.|[^'])*'" ], 
  [ "SEMICOLON",    ";" ], 
  [ "OPERATOR",     "\\+|\\-|\\++" ],
  [ "EQUALS",       "=" ],
  [ "IDENT",        IDENT ], 
  [ "LBRACE",       "\\(" ],
  [ "RBRACE",       "\\)" ],
  [ "LCURLY",       "\\{" ],
  [ "RCURLY",       "\\}" ]
];

var $c      = $m.ROOT;
var TYPES   = {};
var REGEXES = [];
var MAIN_REGEX = null;

for(var i=0,_c1=TOKENS,_l1=_c1.length,t;(t=_c1[i])||(i<_l1);i++){
  TYPES[t[0]] = i; 
  REGEXES.push("(" + t[1] + ")");
}

var EXTRA_REGEX_STRINGS = {
  ARGS: "\\(\s*" + IDENT + "(\\s*,\\s*" + IDENT + ")*\s*\\)"
};

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};


JS2.Class.extend('Tokens', function(KLASS, OO){
  OO.addMember("initialize",function (str) {
    this.orig = str;
    this.str  = str;
  });

  OO.addMember("peek",function () {
    if (this._peek) return this._peek;

    var m = this.str.match(MAIN_REGEX);
    if (!m) return null;

    for(var i=0,_c1=TOKENS,_l1=_c1.length,ele;(ele=_c1[i])||(i<_l1);i++){
      if (m[i+1]) return this._peek = [ i, m[i+1], ele[2] ];
    }
  });

  OO.addStaticMember("regex",function (str) {
    var regexStr = str.replace(" ", "\\s+").replace("><", ">\\s*<").replace(/\<(\w+)\>/g, function($1,$2,$3){
      return "(" + (EXTRA_REGEX_STRINGS[$2] || TOKENS[TYPES[$2]][1])  + ")";
    });

    return new RegExp(regexStr);
  });

  OO.addMember("consume",function (n) {
    this.str   = this.str.substr(n, this.str.length-n);
    this._peek = null;
  });

  OO.addMember("any",function () {
    return this.str.length > 0;
  });
});
var Tokens = $c.Tokens;


JS2.Class.extend('RootParser', function(KLASS, OO){
  OO.addMember("handlers",{});

  OO.addMember("initialize",function () {
    this.out = [];
    this.finished = false;
  });

  OO.addMember("parse",function (tokens) {
    while (tokens.any()) {
      var token = tokens.peek();
      if (!token) return;
      var handlerClass = this.getHandler(token) || token[2];
      if (handlerClass) {
        var handler = new $c[handlerClass];
        handler.parse(tokens);
        this.out.push(handler); 
      } else {
        this.handleToken(token, tokens);
        if (this.finished) return;
      }
    }
  });

  OO.addMember("handleToken",function (token, tokens) {
    this.out.push(token[1]);
    tokens.consume(token[1].length);
  });

  OO.addMember("toString",function () {
    var ret = [];
    for(var _i1=0,_c1=this.out,_l1=_c1.length,ele;(ele=_c1[_i1])||(_i1<_l1);_i1++){
      ret.push(ele.toString()); 
    }
    return ret.join("");
  });

  OO.addMember("getHandler",function () {
    return null;
  });

  OO.addMember("chop",function () {
    this.out.pop();
  });
});

var RootParser = $c.RootParser;

RootParser.extend('ClassParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<CLASS> <IDENT><LCURLY>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.str.match(REGEX);
    var name = m[1];

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "(function ()", content, ")();" ];
  });
});

RootParser.extend('CurlyParser', function(KLASS, OO){
  OO.addMember("handleToken",function (token, tokens) {
    if (token[0] == TYPES.RCURLY) {
      this.curly--;
    } else if (token[0] == TYPES.LCURLY) {
      this.curly++;
    }

    this.$super(token, tokens);
    if (this.curly == 0) this.finished = true;
  });
});

var CurlyParser = $c.CurlyParser;

CurlyParser.extend('ClassContentParser', function(KLASS, OO){
  OO.addMember("getHandler",function (token) {
    console.log(token);
    switch(token[0]) {
      case TYPES.VAR: return "MemberParser";
      case TYPES.FUNCTION: return "MethodParser";
      case TYPES.PRIVATE: return "PrivateParser";
    }
  });
});

RootParser.extend('LineParser', function(KLASS, OO){
  OO.addMember("handleToken",function (token, tokens) {
    this.$super(token, tokens);
    if (token[0] == TYPES.SEMICOLON) {
      this.finished = true;
    }
  });
});

RootParser.extend('MemberParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("var <IDENT>\\s*=\\s*?");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.str.match(REGEX);
    this.name = m[1];
    tokens.consume(m[0].length);

    var parser = new $c.LineParser();
    parser.parse(tokens);
    parser.chop();

    this.out = [ "OO.addMember(", JSON.stringify(this.name), ",",  parser, ");" ];
  });
});

RootParser.extend('MethodParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<FUNCTION> <IDENT><ARGS>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.str.match(REGEX);
    this.out = [ 'METHOD' ];
  });
});


})($m);

exports.mochi = $m;
