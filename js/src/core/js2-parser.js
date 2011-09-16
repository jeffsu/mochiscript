(function (undefined, JS2) {
  JS2.Parser = {
    parse: function(str) {
      var lexer   = new JS2.Lexer(str);
      var tokens  = lexer.tokenize(true);
      var root    = new Content(tokens);
      return root;
    },

    parseFile: function(file) {
      return this.parse(js2.fs.read(file, 'utf8'));
    }
  };

  var KEYWORDS = { 'var': null, 'class': null, 'function': null, 'in': null, 'with': null, 'curry': null, 'static': null, '{module}':null, 'private':null };
  var IDS = JS2.Lexer.IDS;
  IDS['NODE'] = -1;

  var Validator = JS2.Class.extend({
    initialize: function(content) {
      this.content = content;
    },

    validate: function(regex, n) {
      var str = this.getString(n);
      var m   = regex.exec(str);
      if (!m) return false;

      var ret = [ m ];
      var cIdx = 0;
      for (var i=1; i<=m.length; i++) {
        while (this.content[cIdx] && this.content[cIdx][1] == IDS.COMMENT) cIdx++;

        if (!m[i] || m[i].length == 0) {
          ret.push('');
        } else {
          ret.push(this.content[cIdx++][0]);
        }
      }

      if (n == null) {
        var last = [];
        while (cIdx<this.content.length) {
          last.push(this.content[cIdx++][0].toString()); 
        }

        ret.last = last.join('');
      }
      return ret;
    },

    getString: function(n) {
      n = n ? n : this.content.length;
      var ret = [];

      for (var i=0; i<n; i++) {
        var token = this.content[i];
        if (! token) break;
        var str = this.getTokenString(token);
        if (str != null) ret.push(str);
      }

      return ret.join('');
    },

    getTokenString: function(token) {
      if (token[1] == IDS.COMMENT) {
        return null;
      } else if (KEYWORDS.hasOwnProperty(token[0])) {
        return token[0];
      } else if (token[1] == IDS.SPACE) {
        return token[0];
      } else if (token[1] == IDS.IDENT) {
        return 'I';
      } else if (typeof token[0] == 'object') {
        return token[0].name;
      } else if (typeof token[0] == 'string') {
        return token[0];
      }  
    }
  });

  var Content = JS2.Class.extend({
    name: 'Content',
    initialize: function(tokens) {
      this.curlyCount = tokens.curlyCount;
      this.braceCount = tokens.braceCount;
      this.content = [];
      this.tokens = tokens;
      this.handOffs = [];

      this.processTokens(tokens);
    }, 

    processTokens: function() {
      while (!this.tokens.empty() && !this.closed) {
        var token = this.tokens.peek();
        var klass = this.handOff(token);
        if (this.closed) break;

        if (klass) {
          this.handOffs.push(this.newNode(klass, this.tokens));
        } else {
          this.content.push(token);
          this.handleToken(this.tokens.shift());
        }

        if (this.closed) break;
      }    
    },

    handleToken: function(token) {},

    newNode: function(klass, tokens) {
      var node = new klass(tokens); 
      this.content.push([ node, IDS.NODE ]);
      return node;
    },

    validate: function(regex) {
      return (new Validator(this.content)).validate(regex);
    },

    getValidateString: function() {
      return (new Validator(this.content)).getString();
    },

    handOff: function(token) {
      switch (token[1]) {
        case IDS.CLASS: return Klass;
        case IDS.MODULE: return Module;
        case IDS.FOREACH: return Foreach;
        case IDS.SHORT_FUNCT: return ShortFunct;
        case IDS.CURRY: return Curry;
      }
    },

    toString: function() {
      var ret = [];
      for (var i=0; i<this.content.length; i++) {
        ret.push(this.content[i][0].toString()); 
      }
      return ret.join('');
    }
  });

  var Klass = Content.extend({
    name: 'Klass',
    handOff: function(token) {
      if (this.started) this.closed = true;
      switch (token[0]) {
        case '{': this.started = true; return KlassBlock;
      }
    }, 

    toString: function() {
      var v  = this.validate(/(class)(\s+)/);
      var last = v.last;
      var m = last.match(/^([\w$]+(\.[\w$]+)*)(\s+extends\s+([\w$]+(\.?[\w$]+))*)?/);

      var name = m[1];
      var par  = m[4] || 'JS2.Class';
      var source = last.substr(m[0].length);

      return JS2.DECORATOR.klass(name, par, source);
    }
  });

  var Module = Klass.extend({
    name: 'Module',
    toString: function() {
      var v    = this.validate(/(\{module\})(\s+)/);
      var last = v.last;
      var m = last.match(/^([\w$]+(\.[\w$]+)*)/);
      if (m) {
        var name   = m[1];
        var source = last.substr(name.length);
        return JS2.DECORATOR.createModule(name, source);
      } else {
        // raise error
      }
    }
  });


  var Block = Content.extend({
    name: 'Block',
    handleToken: function(token) {
      if (this.tokens.isBalancedCurly(this) && token[0] == '}') {
        this.closed = true;
      }
    }
  });

  var Private = Content.extend({
    name: 'Private',
    handOff: function(token) {
      if (this.started) this.closed = true;
      switch (token[0]) {
        case '{': this.started = true; return Block;
      }
    }, 

    toString: function() {
      var v  = this.validate(/(private)(\s+)/);
      var last = v.last;
      return "// private closure\n" + last.replace(/^\{/, '').replace(/\}$/, '');
    }
  });


  var KlassBlock = Block.extend({
    name: 'KlassBlock',
    handOff: function(token) {
      switch (token[0]) {
        case 'var': return Member;
        case 'function': return Method;
        case 'static': return StaticMember;
        case 'include': return Include;
        case 'private': return Private;
      }
    },

    handleToken: function(token) {
      if (this.tokens.isBalancedCurly(this) && token[0] == '}') {
        this.closed = true;
      }
    },

    toString: function() {
      var str = this.$super();
      return str.replace(/^{/, 'function(KLASS, OO){');
    }
  });

  var Include = Content.extend({
    name: 'Include',
    handleToken: function(token) {
      if (token[0] == ';') this.closed = true;
    },

    toString: function() {
      var v = this.validate(/^(include)(\s+)/);
      return "OO.include(" + v.last.replace(/;$/, ');');
    }
    
  });

  var StaticMember = Content.extend({
    name: 'StaticMember',
    handOff: function(token) {
      if (this.started) this.closed = true;

      switch (token[0]) {
        case 'var': this.started = true; return Member;
        case 'function': this.started = true; return Method;
      }
    },

    toString: function() {
      var member = this.handOffs[0];
      if (!member) return '';
      var ret = member.toString();
      return ret.replace(/addMember/, 'addStaticMember');
    }
  });

  var Method = Content.extend({
    name: 'Method',
    handOff: function(token) {
      if (this.started) this.closed = true;
      if (token[0] == '(') {
        return Braces;
      } else if (token[0] == '{') {
        this.started = true;
        return Block;
      }
    },

    toString: function () {
      var v  = this.validate(/^(function)(\s+)(I)(\s*)(Braces)(\s*)(Block)/);
      return 'OO.addMember("' + v[3] + '",' + "function" + v[2] + v[5] + ' ' + v[7] + ');';
    }
  });

  var Member = Content.extend({
    name: 'Member',
    handleToken: function(token) {
      if (token[0] == ';') this.closed = true;
    },

    toString: function () {
      var v = this.validate(/(var)(\s+)(I)(\s*)(=)?(\s*)/);
      var last = v.last.replace(/;$/, '');
      if (last.length == 0) last = 'null';

      return 'OO.addMember("' + v[3] + '",' + last + ');';
    }
  });

  var Braces = Content.extend({
    name: 'Braces',
    handleToken: function(token) {
      if (this.tokens.isBalancedBrace(this) && token[0] == ')') {
        this.closed = true;
      }
    } 
  });

  var Foreach = Content.extend({
    cache: { count: 0 },
    name: 'Foreach',
    handOff: function(token) {
      if (this.started) {
        this.closed = true;
      }
      switch (token[0]) {
        case '(': return Braces;
        case '{': this.started = true; return Block;
      }
    },

    toString: function() {
      this.cache.count++;
      var v = this.validate(/(foreach)(\s*)(Braces)(\s*)(Block)/);
      var ret =  "for" + this.getBrace(v[3]) + v[5].toString();
      this.cache.count--;
      return ret;
    },

    getBrace: function(brace) {
      var n = this.cache.count;
      var collectionName = "_c" + n;
      var l = "_l" + n;

      var v = brace.validate(/(\()(\s*)(var)(\s+)(I)(\s*\:\s*(I))?(\s+)(in)(\s+)/);
      if (!v) return '';
      var iteratorName   = v[7] || "_i" + n;

      var holder = v[5];
      var collection = v.last.replace(/\)$/, '');

      return "(var " + iteratorName + "=0," +
              collectionName + "=" + collection + "," +
              l + "=" + collectionName + ".length," +
              holder + ";(" +
              holder + '=' + collectionName + '[' + iteratorName + '])||(' +
              iteratorName + '<' + l + ');' +
              iteratorName + '++)';
    }
  });

  var ShortFunct = Content.extend({
    name: "ShortFunct",
    handOff: function(token) {
      if (this.started) {
        this.closed = true;
        this.semi = (new Validator(this.tokens.toArray())).validate(/^(\s*)([^\s\w$])/, 2) ? '' : ';';
      } 

      switch (token[0]) {
        case '(': return Braces;
        case '{': this.started = true; return Block;
      }
    },

    parseArgs: function(str) {
      // (arg1, arg2 with scope1, scope2 binds bindingVar)
      var m =  str.match(/^\((\s*([\w\$]+)(\s*,\s*[\w\$]+)*)?(\s*with\s+(([\w\$]+)(\s*,\s*[\w\$]+)*))?(\s*binds\s+(.+))?\)/);
      if (!m) {}  // raise error

      return {
        braces: '(' + (m[1] || '') + ')',
        scope:  m[5],
        binds:  m[9]
      };
    },

    toString: function() {
      var scopes   = null;
      var inScopes = null;

      var v    = this.validate(/(#)(Braces)?(\s*)(Block)/);
      var args = this.parseArgs(v[2] ? v[2].toString() : '($1,$2,$3)');
      var body = v[4];

      // we need a function within a function
      if (args.binds || args.scope) {
        var scope   = args.scope || '';
        var inScope = scope;

        // need to pass in __self and bind to __self
        if (args.binds) {
          var comma = scope == '' ? '' : ',';
          inScope = scope.replace(/^/, '__self' + comma);
          scope   = scope.replace(/^/,  args.binds + comma);
          
          return '(function(' + inScope + '){' + 'var f = function' + args.braces + body + ';' + ' return function() { return f.apply(__self, arguments)};})(' + scope + ')' + this.semi; 
        } 
        
        // no binding, just use scoping 
        else {
          return '(function(' + inScope + '){' + 'return function' + args.braces + body + ';' + '})(' + scope + ')' + this.semi; 
        }
      } 
      
      // just a normal function
      else {
        return "function" + args.braces + body + this.semi;
      }
    }
  });

  var Curry = Content.extend({
    name: "Curry",
    handOff: function(token) {
      if (this.started) {
        var v = (new Validator(this.tokens.toArray())).validate(/^(\s*)([\w$]+)/, 2);
        if (v) this.addSemiColon = true;
        this.closed = true;
      }

      if (this.nbraces == null) this.nbraces = 0;

      switch (token[0]) {
        case '(': return Braces;
        case '{': this.started = true; return Block;
      }
    },

    toString: function() {
      var v = this.validate(/(curry)(\s*)(Braces)?(\s*)(with)?(\s*)(Braces)?(\s*)(Block)/);

      var scopeOuter = (v[5] ? v[7].toString() : "()");
      var scopeInner = scopeOuter.replace(/\bthis\b/, '$this');

      var ret = [ '(function' + scopeInner + '{return function' ];

      // args
      ret.push(v[3] ? v[3].toString() : '($1,$2,$3)');

      // block
      ret.push(v[9].toString());

      // close outer block
      ret.push("})");

      // scope
      ret.push(scopeOuter);

      if (this.addSemiColon) ret.push(';');

      return ret.join('');
    }
  });

  JS2.require = function(file) {
    var str = JS2.Parser.parseFile(file + '.js2').toString(); 
    eval(str);
  }

  JS2.parse = function(str) { return this.Parser.parse(str); };
  JS2.parseFile = function(file) { return this.Parser.parseFile(file); };
  JS2.render = function(str) { return this.parse(str).toString(); };
  JS2.renderFile = function(file) { return this.parseFile(file).toString(); };

})(undefined, JS2);
