$(function () {
  $('#btn').click(function () {
    new Demo().sayHello();
  });
});

class Demo {
  function sayHello() {
    alert('Hello Mochi!');
  }
}
