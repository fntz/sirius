
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
    var result = JSON.stringify({"my_model": JSON.parse(result)});
    assert(j1 == result);
  });

  test("#to_html", function() {
    var m = new MyModel({"id": 10, "title": "my title", "description": "text..."});
    var r = m.to_html();
    var n = "<b class = 'my-model-id'>10</b><span class = 'my-model-title'>my title</span><div>text...</div>";
    assert(r == n)
  });

  test("#from_json", function() {
    var j = JSON.stringify({"id": 10, "description": "text"});

    var m = MyModel.from_json(j);

    assert(m.get("id") == 10);
    assert(m.get("title") == "default title");
    assert(m.get("description") == "text");
  });

  test("#from_html", function() {
    SiriusApplication.adapter = new JQueryAdapter();
    var m = MyModel.from_html("#my-model-form");
    
    assert(m.get("id") == 1);
    assert(m.get("title") == "new title");
    assert(m.get("description") == "text...");
  });

  suite("relations", function() {
    var p0 = new Person({id: 1}),
        p1 = new Person({id: 2}),
        n0 = new Name({name: "abc"}),
        n1 = new Name({name: "qwe"}),
        g0 = new Group({name: "group-0"}),
        g1 = new Group({name: "group-1"}),
        g2 = new Group({name: "group-2"});

        p0.add_group(g0);
        p0.add_group(g1);
        p1.add_group(g2);
        p0.add_name(n0);

    test("#has_*", function() {
      assert(p0.attributes.length == 3);
      assert(p0.get("group").length == 2);
      assert(p1.get("group").length == 1);

      //check feedback
      assert(g0.attributes.length == 2);

      assert(g0.get('person_id') == 1);
      assert(g1.get('person_id') == 1);
      assert(g2.get('person_id') == 2);

      assert.throw(function() { p0.add_name(n1);});
    });

    test("#to_json&html", function() {
      var z = {"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}],"name":{"name":"abc","person_id":1}};

      var j = JSON.parse(p0.to_json());

      assert(z["id"] == j["id"]);
      assert(z["name"]["person_id"] == j["name"]["person_id"]);
      assert(z["name"]["name"] == j["name"]["name"]);
      assert(j["group"].length == 2);
      assert(z["group"][0]["name"] == j["group"][0]["name"]);

      var n = "<div>1</div><p class = 'group'><span>group-0</span><div>1</div>,<span>group-1</span><div>1</div></p><div><div>abc</div><div>1</div></div>";

      assert(p0.to_html() == n);
    });
    test("#from_json, from_html", function() {
      var c = function(m){console.log(m);}
      var j = JSON.stringify({"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}],"name":{"name":"abc","person_id":1}})

      var z = Person.from_json(j, {group: Group, name: Name});

      assert(p0.get("id") == z.get("id"));
      assert(p0.get("name").get("name") == z.get("name").get("name"));
      assert(p0.get("group")[0].get("person_id") == z.get("group")[0].get("person_id"));
      assert(z.get("group").length == 2);

      var z0 = Person.from_json(j);

      assert(p0.get("id") == z0.get("id"));
      assert(z0.get("name")["name"] == p0.get("name").get("name"));
      assert(p0.get("group")[0].get("person_id") == z0.get("group")[0]["person_id"]);
      assert(z0.get("group").length == 2);

    });
  });



});