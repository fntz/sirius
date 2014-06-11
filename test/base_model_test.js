
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

  

});