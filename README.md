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

More on Syntax
--------------

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


Authors
-------

  1. [Jeff Su](https://github.com/jeffsu)
  1. [Hong Hao](https://github.com/agate)
