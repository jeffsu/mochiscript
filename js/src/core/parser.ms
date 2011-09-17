(function ($m) {
  var TOKENS = [
    [ "CLASS",    "class" ], 
    [ "IDENT",    "class" ], 
    [ "OPERATOR", "\\+|\\-|\\++" ]
  ];

  var TYPES   = {};
  var REGEXES = {};
  foreach (var t:i in TOKENS) {
    TYPES[t[0]] = i; 
    REGEXES[t[0]] = t[1];
  }

  class RegexBuilder {
    private {
      var cache = {};
    }

    static function get(format) {
      var regex = cache[format];
      if (!regex) {
        return cache[format] = this.build(format);
      }
    }

    static function build(format) {
      var regexStr = format.replace(/<(\w+)>/, #{ return REGEXES[$1]; });
      regexStr = regexStr.replace(/S/, "\\s");
    }
  }

  class Tokens {
    function initialize(str) {
      this.str = str;
      this.out = [];
    }

    function push(str) {
      this.out.push(out);
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

    function parse(tokens) {
      var token = tokens.peek(); 
      var type  = token[0];
      var text  = token[1];
      var consumer = this.nextConsumer(type) || this;
      consumer.handle(type, text, tokens);
    }

    function consume(format) {
      var regex = this.formats[format];
      if (! regex) {
        this.buildRegex(format);
      }
    }

    function buildRegex(format) {
      var regexStr = format.replace(/\<(\w+)\>/, function () {
         
      });
    }

    function handle(type, text, tokens) {
      tokens.push(text); 
      tokens.chomp(text.length);
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
