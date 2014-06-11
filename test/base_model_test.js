
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

  test("#to_json", function() {
    var m = new MyModel();

    m.set("id", 10);
    m.set("description", "text");

    var j0 = m.to_json();
    var result = JSON.stringify({"id": 10, "title": "default title", "description": "text"});
    assert(j0 == result);

    var j1 = m.to_json(true);
    var result = JSON.stringify({"my-model": JSON.parse(result)});
    assert(j1 == result);
  });

  test("#to_html", function() {
    SiriusApplication.adapter = new JQueryAdapter();
    var m = new MyModel({"id": 10, "title": "my title", "description": "text..."});
    var r = m.to_html();
    assert($(r[0]).prop('tagName') == "B");
    assert($(r[0]).text() == "10");
    assert($(r[0]).attr('class') == 'my-model-id');

    assert($(r[1]).prop('tagName') == "SPAN");
    assert($(r[1]).text() == "my title");
    assert($(r[1]).attr('class') == "my-model-title");

    assert($(r[2]).prop('tagName') == "DIV");
    assert($(r[2]).text() == "text...");
    assert($(r[2]).attr('class') == "description");
  });

  test("#from_json", function() {
    var j = JSON.stringify({"id": 10, "description": "text"});

    var m = MyModel.from_json(j);

    assert(m.get("id") == 10);
    assert(m.get("title") == "default title");
    assert(m.get("description") == "text");
  });

  


});