(function ($m) {
  var TOKENS = [
    [ "KEYWORD",  "class|module" ], 
    [ "OPERATOR", "\\+|\\-|\\++" ]
  ];

  var IDS = [];
  foreach (var t:i in TOKENS) {
    IDS[t[0]] = i; 
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

  class Consumer {
    function parse(tokens) {
    }
  }

  class Curlies extends Content {
    
  }

  class Content extends Consumer {
    function parse(tokens) {
      var token = tokens.peek(); 
      var type  = token[0];
      var text  = token[1];
      var consumer = this.nextConsumer(type);
    }

    function nextConsumer(type) {
      switch (type) {
        case CLASS: return factory.curlies;
        case IDENT: return factory.ident;
      }
    }
  }

})($m);
