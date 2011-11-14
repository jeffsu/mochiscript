var foo = <<END:jsml;
  %div hello world
    %ol.fields
    %button aaa
END

var $$template = <<END:jsml
  %fieldset
    %ol.fields
    %button{ onclick: "c.addField(); return false" } Add Field
END


$m.test(#(assert){
  assert.eq('<div>hello world</div>', foo.result());
  console.log(foo.result());
  console.log($$template.result());
});
