var foo = <<END:jsml;
  %div hello world
END

var $$template = <<END:jsml
  %fieldset
    %ol.fields
    %button{ onclick: 'c.addField(); return false' } Add Field
END


$m.test(#(assert){
  assert.eq('<div>hello world</div>', foo.result());
  assert.eq('<fieldset><ol class="fields"></ol><button onclick="c.addField(); return false">Add Field</button></fieldset>', $$template.result());
});
