class CLI {
  private {
    var COMMANDS = {
      help:    'help',
      render:  'render',
      compile: 'compile',
      watch:   'watch'
    };
  }

  function run(args) {
    var opts = this.parseOpts(args);
    var options = opts[0];
    var command = opts[1];
    var files   = opts[2];
  }

  function parseOpts(args) {
    var files   = [];
    var options = {};
    var command = null;

    var endedArgs = false;

    foreach (var arg:i in args) {
      if (endedArgs) {
        files.push(arg);
      }

      else if (COMMANDS[arg]) {
        command   = arg;
        endedArgs = true;
      }

      else {
        var setting = arg.match(/^(\w+)(?:=(.*))?$/);
        if (setting) options[setting[0]] = setting[1] || 'true';
      }
    }

    return [ options, command, files ];
  }
}
