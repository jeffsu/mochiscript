(function ($m) {
  var TOKENS = [
    [ "SPACE",    "\s+" ],
    [ "CLASS",    "class" ], 
    [ "IDENT",    "[\\$\\w]+" ], 
    [ "OPERATOR", "\\+|\\-|\\++" ]
  ];

  var TYPES   = {};
  var REGEXES = [];
  var MAIN_REGEX = null;

  foreach (var t:i in TOKENS) {
    TYPES[t[0]] = i + 1; 
    REGEXES.push("(" + t[1] + ")");
  }

  var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));
  var parsers    = null;

  $m.parse = function (str) {
    loadParsers();
    var tokens = new Tokens(str);
    return parsers.root.parse(tokens);
  };

  class Tokens {
    function initialize(str) {
      this.origStr = str;
      this.str     = str;
      this.length  = str.length;
      this.consumed = 0;
    }

    function peek() {
      var m = this.str.match(MAIN_REGEX);
      foreach (var tokens:i in TOKENS) {
        if (m[i+1]) {
          return [ i+1, m[i+1] ];
        }
      }
      return null;
    }

    function chomp(len) {
      this.consumed += len;
    }

    function any() {
      return this.consumed < this.length;
    }
  }

  class ConsumerFactory {
    function initialize() {
      this.klass   = new Klass();
      this.curlies = new Curlies();
    }
  }

  class Curlies extends Content {
    
  }

  class Klass extends Content {
    function handle(type, text, tokens) {
      this.match("<KLASS>S<IDENT>S*{", tokens);
    }
  }

  class Content extends Consumer {
    function initialize() {
      this.formats = {};
    }

    function toJS(str) {
      var consumer = this.nextConsumer(type) || this;
      return consumer.handle(type, text, tokens);
    }

    function handle(tokens) {
      var token = tokens.peek(); 
      var type  = token[0];
      var text  = token[1];

      var out = [];
      var consumer = this.nextConsumer();
    }

    function nextConsumer(type) {
      switch (type) {
        case TYPES.CLASS: return factory.curlies;
        case TYPES.IDENT: return factory.ident;
      }
      return null;
    }
  }

})($m);
