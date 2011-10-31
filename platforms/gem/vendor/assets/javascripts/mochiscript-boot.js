
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
    for(var i=0,_c1=arguments,_l1=_c1.length,arg;(arg=_c1[i])||(i<_l1);i++){
      $m.ADAPTER.out(arg);
      if (i < arguments.length-1) {
        $m.ADAPTER.out(',');
      }
    }
  };

  $m.outs = function () {
    for(var _i1=0,_c1=arguments,_l1=_c1.length,arg;(arg=_c1[_i1])||(_i1<_l1);_i1++){
      $m.ADAPTER.outs(arg);
    }
  };


  return $m;
})(undefined, $m);


