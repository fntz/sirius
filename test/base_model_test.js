
suite("BaseModel", function() {
  test("should define attributes for model", function() {
    var m = new MyModel();

    assert(m.get('id') == null);
    assert(m.get('description') == null);
    assert(m.get('title') == "default title");

    assert(m.attributes.length == 3);

    m.set("id", 10);
    m.set("title", "new title");
    m.set("description", "text");

    assert(m.get('id') == 10);
    assert(m.get('description') == "text");
    assert(m.get('title') == "new title");

    var om = new MyModel({"id": 10});

    assert(om.get('id') == 10);
    assert(om.get('description') == null);
    assert(om.get('title') == "default title");
  });

  test("validate", function() {
    var m = new ModelwithValidators();
    m.validate();

    assert(m.valid() == false);
    assert(Object.keys(m.errors).length == 2);

    assert(m.errors['id'].length == 3);
    m.set("id", "abc");
    m.validate();
    assert(m.errors['id'].length == 2);
    m.set("id", 100);
    m.validate();
    assert(m.errors['id'].length == 1);
    m.set("id", 3);
    m.validate();

    assert(Object.keys(m.errors).length == 1);

    assert(m.errors['title'].length == 2);
    m.set("title", "title123");
    m.validate();
    assert(m.errors['title'].length == 2);
    m.set("title", "title");
    m.validate();
    assert(m.errors['title'].length == 1);
    m.set("title", "New");
    m.validate();
    assert(Object.keys(m.errors).length == 0);
  });


});