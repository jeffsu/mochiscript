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

Authors
-------

  1. [Jeff Su](https://github.com/jeffsu)
  1. [Hong Hao](https://github.com/agate)
