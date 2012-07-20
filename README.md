Summary
=======

Mochiscript is a superset of the JavaScript language that adds more Object-Oriented features such as: methods, inheritance, mixins, etc... What this means is that Mochiscript IS Javascript.  Mochiscript currently supports Ruby on Rails 3.1 (via asset pipeline) and Node.js.

More on Mochiscript features and syntax here: https://github.com/jeffsu/mochiscript/wiki/Mochiscript-Syntax

Installation
============

In Rails >3.1
-------------

In the Gemfile, add this line:

    gem 'mochiscript'

In app/assets/javascripts/application.js, add mochiscript

    //= require mochiscript
    
Now, you should be able to create ".ms" files and it'll be included as javascript using the new rails asset pipeline.

### An example:

Create a simple mochiscript (app/assets/javascripts/hello.ms):

    class Hello {
      function say() {
        alert('hello');
      }
    }

Now include it in application.js

    //= require hello

Now on your page, you should be able to put this code in after your javascript include section:

    <script>
      var obj = new Hello();
      obj.say();
    </script>

In Node.js
----------

    npm install mochiscript

In hello.ms:

    export class Hello {
      function say() {
        console.log("hello");
      }
    }

In main.js:
    
    require('mochiscript');
    var Hello = require('./hello');
    var obj   = new Hello();
    obj.say();

### CLI

Parsing a file:

    ms-parse <filename>

Running an ms file:
 
    ms-run <filename>

Compiling files in a directory:

    ms-watch <src> <dest> <template>

  1. src: source directory with .ms files
  1. dest: destination directory to write .js files
  1. template file (optional).  This will allow you to templatize mochiscript.  Just make sure the file has "__MOCHI__" in it.


Mochiscript in the browser
--------------------------

### Bootstrap File

Please include this file before requiring any mochiscript compiled file: [mochiscript.js](https://cloud.github.com/downloads/jeffsu/mochiscript/mochiscript.js)
  
### Middleware

Using connect/express:

    var options = {
      src: "views",

    };
    app.use(require('mochiscript').middleware(options));

## More on Syntax

Mochiscript syntax is a superset of JavaScript's.  This means that any JavaScript you write will run just fine in Mochiscript.  Mochiscript simply adds extra features that make development life a little easier.

## Object Oriented Features

### Classes

Classes can be created with the "class" keyword.  If you wish to have a custom initializer function, just include a method called "initialize".

    class Hello {
      var defaultMessage = "Just say hello";
 
      function initialize(message) {
        this.message = message || this.defaultMessage;
      }
 
      function say() {
        console.log(this.message);
      }
    }
 
    var obj = new Hello("what's up?");

### Instantiator

The method "initialize" is the default instance method used to instantiate an object (just like Ruby).

    class Foo {
      function initialize(arg1, arg2) {
        this.args = [ arg1, arg2 ];
        console.log("Instance of Foo created!", arg1, arg2);
      }
    }

    var foo = new Foo("hello", "world");

### Inheritance

    class Goodbye extends Hello {
      var defaultMessage = "Goodbye";
      function say() {
        console.log("Saying:");
        this.$super();
      }
    }

### Mixins

    module World {
      function world() {
        console.log('world');
      }
    }
 
    class HelloWorld extends Hello {
      include World;
    }

### Private Section

This is a little unorthodox part of Mochiscript which allows you to add a "closed" section that only methods in the scope of the class can access.

    class MyClass {
      private {
        var CONSTANT_VAR = "constant";
      }
 
      function initialize(data) {
        this.data = data || CONSTANT_VAR;
      }
    }

### Accessing "self"

A lot of times, you need access to the "this" object in a callback.  The problem is that "this" often points to something else in a different context.  The workaround is usually:

    class Foo {
      var hello = "hello";
      function setup() {
        var self = this;
        $('.hello').click(#{ alert(self.hello) }); 
      }
    }

In mochiscript, it is no longer necessary to create a "self" variable.  Its given to you in all methods:

    class Foo {
      var hello = "hello";
      function setup() {
        $('.hello').click(#{ alert(self.hello) });
      }
    }

## Syntactic Sugar

### Shorthand Functions

There are two ways to use this feature:

    var myFunct = #{ console.log($1) }; // prints out first argument (supports up to 3 args)
    var myFunct = #(msg){ console.log(msg) };

### Shorthand returns

    [ 1, 2, 3 ].map(#{ => $1 + 1 });

### Foreach
    
    var array = [ 'hello', 'world' ];
    foreach (var word in array) {
      console.log(word);
    }

    // foreach with iterator
    foreach (var word:i in array) {
      console.log(i, word);
    }

### Heredocs

    var message = <<END;
      this is a lot of text
      here.
    END

### Enumerable Functions (experimental)

    var greetings = [ 'hi', 'hello' ];
    var mapped    = greetings#map { $1 + " there!" };
    var some      = greetings#some { $1 == 'hi' };

## Node-specific module exporters

Mochiscript has two helpers for exporting your files:

    public class MyClass {

    }
    
    // equivalent to 
    // exports.MyClass = MyClass;

Or make it the default export:
   
    export class MyClass {

    }
   
    // equivalent to
    // module.exports = MyClass;

Authors
-------

  1. [Jeff Su](https://github.com/jeffsu)
  1. [Hong Hao](https://github.com/agate)
