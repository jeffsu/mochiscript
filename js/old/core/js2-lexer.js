(function (undefined, JS2) {
  var TOKENS = [ 
    [ 'COMMENT', "\\/\\/|/\\*" ],
    [ 'SPACE', "\\s+" ],
    [ 'REGEX', "\\/" ],
    [ 'CLASS', "\\bclass\\b" ],
    [ 'MODULE', "\\bmodule\\b" ],
    [ 'STATIC', "\\bstatic\\b" ],
    [ 'include', "\\binclude\\b" ],
    [ 'SHORT_FUNCT', "#\\{|#\\(" ],
    [ 'FOREACH', "\\bforeach\\b" ],
    [ 'CURRY', "\\bcurry\\b" ],
    [ 'IDENT', "[\\w$]+" ],
    [ 'DSTRING', '"' ],
    [ 'SSTRING', "'" ],
    [ 'ISTRING', "%\\{" ],
    [ 'HEREDOC', "<<-?\\w+" ],
    [ 'OPERATOR', "(?:\\+\\+|\\-\\-|[^\\w])" ]
  ];

  var IDS = {};
  var REGEX_TOKENS = [];
  for (var i=0,token; token=TOKENS[i]; i++) {
    IDS[token[0]] = i;
    REGEX_TOKENS.push("(" + token[1] + ")");
  }

  var PRIMARY_REGEX = new RegExp("^(" + REGEX_TOKENS.join('|') + ")");

  JS2.Class.extend('Lexer', {
    TOKENS: TOKENS,
    PRIMARY_REGEX: PRIMARY_REGEX,
    IDS: IDS,

    initialize: function(str) {
      this.tokens = (typeof str == 'string') ? new JS2.Lexer.Tokens(str) : str;
    },

    tokenize: function(root) {
      if (root) {
        var m = this.tokens.match(/^#!.*/);
        if (m) this.tokens.chomp(m[0].length);
      }

      while (!this.tokens.finished()) {
        if (! this.consume()) {
          if (root) {
            console.log("ERROR:\n" + this.tokens.toArray().join("\n") + "\n" + this.tokens.str);
            break;
          } else {
            return false;
          }
        }
      }
      return this.tokens;
    },

    consume: function() {
      var m = this.tokens.match(PRIMARY_REGEX)
      if (!m) return false;

      if (m[0] == '/' && this.tokens.divideCompatible()) {
        this.tokens.push([ '/', IDS.OPERATOR ]); // operator
        this.tokens.chomp(1);
        return  true;
      }

      // module hack
      if (m[0] == 'module') {
        if (this.tokens.match(/^module\s+\w/)) {
          this.tokens.push([ '{module}', this.IDS.MODULE ]);
        } else {
          this.tokens.push([ 'module', this.IDS.IDENT ]);
        }
        this.tokens.chomp(6);
        return true;
      }

      for (var i=0,tokenDef;tokenDef=this.TOKENS[i];i++) {
        if (m[0] == m[i+2]) {
          var klass = JS2.Lexer[tokenDef[0]];

          if (klass) {
            var lexer = new klass(this.tokens);
            if (lexer.consume()) {
              return true;
            }
          } else {
            var type = tokenDef[0];
            this.tokens.push([ m[0], i ]);
            this.tokens.chomp(m[0]);
            return true;
          }
        }
      }
    }
  });

  JS2.Lexer.IDS = IDS;
  JS2.Lexer.extend('Lexer.REGEX', {
    REGEX: /^\/(?!\s)[^[\/\n\\]*(?:(?:\\[\s\S]|\[[^\]\n\\]*(?:\\[\s\S][^\]\n\\]*)*])[^[\/\n\\]*)*\/[imgy]{0,4}(?!\w)/,
    ID: IDS.REGEX,

    consume: function() {
      return this.consumeRegex(this.REGEX);
    },

    consumeRegex: function(regex) {
      var m = this.tokens.match(regex);

      if (m) {
        this.tokens.push([ m[0], this.ID ]);
        return this.tokens.chomp(m[0].length);
      }

      return false;
    }
  });

  JS2.Lexer.extend('Lexer.SHORT_FUNCT', {
    ID: IDS.SHORT_FUNCT,
    consume: function() {
      this.tokens.chomp(1);
      this.tokens.push([ '#', this.ID ]);
      return true;
    }
  });


  JS2.Lexer.REGEX.extend('Lexer.SSTRING', {
    REGEX: /^'[^\\']*(?:\\.[^\\']*)*'/,
    ID: IDS.SSTRING
  });

  JS2.Lexer.REGEX.extend('Lexer.DSTRING', {
    REGEX: /^"[^\\"]*(?:\\.[^\\"]*)*"/,
    ID: IDS.DSTRING
  });

  JS2.Lexer.REGEX.extend('Lexer.ISTRING', {
    REGEX_NEXT: /^((\\#|[^#])*?)(#{|})/,
    REGEX: /^%\{/,
    ID: IDS.ISTRING,
    sanitize: function(str) {
      return JSON.stringify(str);
    },
    consume: function() {
      var m = this.tokens.match(this.REGEX);
      if (!m) return false;
      this.tokens.chomp(2);

      // not really ends...
      var toEnd = false;
      while (1) {
        var m = this.tokens.match(this.REGEX_NEXT);
        if (m) {
          var matched = m[1];
          if (m[3] == '#{') {
            this.tokens.push([ this.sanitize(matched) + '+(', this.ID ]);
            this.tokens.chomp(m[0].length-1);
            var block = new JS2.Lexer.Block(this.tokens);
            block.tokenize();
            this.tokens.push([ ')+', this.ID ]);
            toEnd = true;
          } else if (m[3] == '}' || m[0] == '}') {
            this.tokens.push([ this.sanitize(matched), this.ID ]);
            this.tokens.chomp(m[0].length);
            break;
          }
        } else {
          break;
        }
      }
      return true;
    }
  });

  JS2.Lexer.ISTRING.extend('Lexer.HEREDOC', {
    REGEX_NEXT: /^((\\#|[^#])*?)(#{|\r?\n)/,
    REGEX: /^<<\-?(\w+)(?::(\w+))?\s*\r?\n/m,
    ID: IDS.HEREDOC,
    consume: function() {
      var m = this.tokens.match(this.REGEX);
      if (!m) return false;

      var templateEngine = m[2];
      this.tokens.chomp(m[0].length);
      this.tokens.push([ "\n", IDS.SPACE ]);

      var mIndent = this.tokens.match(/^(\s*)([^\s])/m);
      var spacing = mIndent[1];
      var nspace  = mIndent[1].length;
      var ender = new RegExp("^\\s*" + m[1] + "(\\r?\\n)?");

      var first   = true;
      var noChomp = false;
      if (templateEngine) {
        this.tokens.push([ 'JS2.TEMPLATES["' + templateEngine + '"].process(', IDS.IDENT ]);
      }

      while (1) {
        var e = this.tokens.match(ender);
        if (e) {
          this.tokens.chomp(e[0].length);
          break;
        } 

        if (noChomp) {
          noChomp = false;
        } else {
          this.tokens.chomp(nspace);
        }

        var next = this.tokens.match(this.REGEX_NEXT);
        if (next) {
          var str    = next[1];
          var ending = next[2];

          if (next[1]) {
            this.tokens.chomp(next[1].length);
            this.tokens.push([ (first ? '' : '+') + this.sanitize(next[1]).replace(/"$/, '\\n"') , IDS.DSTRING ]);
          }

          if (next[3] == '#{') {
            this.tokens.chomp(1);
            this.tokens.push([ '+(', IDS.DSTRING ]);
            var block = new JS2.Lexer.Block(this.tokens);
            block.tokenize();
            this.tokens.push([ ')', IDS.DSTRING ]);
            noChomp = true;
          } else {
            this.tokens.chomp(next[3].length);
          }
        }
        first = false;
      }

      if (templateEngine) {
        this.tokens.push([ ')', IDS.IDENT ]);
      }

      this.tokens.push([ ';', IDS.OPERATOR ]);
      return true;
    }
  });


  JS2.Lexer.extend('Lexer.Block', {
    initialize: function(tokens) {
      this.$super(tokens);
      this.started = false;
    },

    consume: function() {
      if (! this.started) {
        this.started = true;
        this.tokens.chomp(1);
        this.curlyCount = 1;
        return true;
      } else if (this.tokens.str.charAt(0) == '{') {
        this.curlyCount++;
      } else if (this.tokens.str.charAt(0) == '}') {
        this.curlyCount--;
      }

      if (this.curlyCount == 0) {
        this.tokens.chomp(1);
        return false;
      } else {
        this.$super();
        return true;
      }
    } 
  });

  JS2.Lexer.extend('Lexer.COMMENT', {
    ID: IDS.COMMENT,
    consume: function() {
      var m = this.tokens.match(/^\/\/.*/);
      if (m) {
        this.tokens.push([ m[0], IDS.COMMENT ]);
        this.tokens.chomp(m[0].length);
        return true;
      }

      var str = this.tokens.str;
      var mode = 0;
      for (var i=0; i<str.length; i++) {
        if (str.charAt(i) == '*') {
          mode = 1;
        } else if (str.charAt(i) == '/' && mode == 1) {
          mode = 2;
        } else {
          mode = 0;
        }

        if (mode == 2) {
          this.tokens.push([ str.substr(0, i+1), IDS.COMMENT ]);
          this.tokens.chomp(i+1);
          return true;
        }
      }
      return false;
    }
  });




  JS2.Class.extend('Lexer.Tokens', {
    initialize: function(str) {
      this.curlyCount = 0;
      this.braceCount = 0;
      this.tokens = [];
      this.index  = 0;
      this.str    = str;
      this.orig   = str;
      this.before = [];
    },

    divideCompatible: function() {
      var last = this.lastNonSpace();
      return (last[0].match(/(\}|\)|\+\+|\-\-)$/) || last[1] == IDS.IDENT);
    },

    lastNonSpace: function() {
      var idx   = this.tokens.length - 1;
      var token = this.tokens[idx];
      while (token && token[1] == IDS.SPACE) {
        token = this.tokens[--idx];
      }
      return token;
    },

    toArray: function() {
      return this.tokens;
    },

    match: function(regex) {
      return this.str.match(regex);
    },

    compare: function(str) {
      return this.str.substr(0, str.length) == str;
    },

    // stuff can be string, integer, or regex
    // will return true if it actually made the string 
    // smaller
    chomp: function(stuff) {
      var len = this.str.length;
      if (typeof stuff == 'number') {
        this.str = this.str.substr(stuff);
      } else if (typeof stuff == 'string') {
        this.str = this.str.substr(stuff.length);
      } else if (stuff instanceof RegExp) {
        var m = this.str.match(stuff);
        if (m) {
          this.str = this.str.substr(m[0].length);
        }
      }
      return len > this.str.length;
    },

    finished: function(token) {
      return this.str.length == 0;
    },

    push: function(token) {
      this.tokens.push(token);
    },

    pop: function() {
      var ret = this.tokens.pop();
      this.before.push(ret);
      return ret;
    },

    peek: function() {
      return this.tokens[0];
    },

    shift: function() {
      var token = this.tokens.shift();
      var str = token[0];
      switch(str) {
        case '{': this.curlyCount++; break;
        case '}': this.curlyCount--; break;
        case '(': this.braceCount++; break;
        case ')': this.braceCount--; break;
      }
      this.before.unshift(token);
      return token;
    },

    freeze: function(obj) {
      obj.curlyCount = this.curlyCount;
      obj.braceCount = this.braceCount;
    },

    isBalancedCurly: function(obj) {
      return obj.curlyCount == this.curlyCount;
    },

    isBalancedBrace: function(obj) {
      return obj.braceCount == this.braceCount;
    },

    empty: function() {
      return this.tokens.length <= 0; 
    },

    charAt: function(n) {
      return this.str.charAt(n);
    },

    indexOf: function(n) {
      return this.str.indexOf(n);
    }

  });
})(undefined, JS2);
