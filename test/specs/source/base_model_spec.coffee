describe "BaseModel", ->
  it "Work with attributes", ->
    model = new MyModel()

    expect(model.get('id')).toBeNull()
    expect(model.id()).toBeNull()
    expect(model.get('title')).toEqual("default title")
    expect(model.title()).toEqual("default title")
    expect(model.get('description')).toBeNull()
    expect(model.description()).toBeNull()

    model.set('id', 10)
    expect(model.id()).toEqual(10)

    model.id(100)
    expect(model.get('id')).toEqual(100)

    model = new MyModel({id: 1, title: "new title", description: "description"})
    expect(model.id()).toEqual(1)
    expect(model.title()).toEqual("new title")
    expect(model.description()).toEqual("description")

  it "Validation", ->

  describe "Convertable", ->

    beforeEach ->
#      if !load
#        $.ajax "fixtures/model-form.html",
#          success: (html)->
#            $("body").append(html)
#            load = true


    it "to_json", ->
      model = new MyModel()
      model.id(10)
      model.description("text")

      json = model.to_json()
      expected = JSON.stringify({"id": 10, "title": "default title", "description": "text"})

      expect(json).toEqual(expected)

      json = model.to_json(true)
      expected = JSON.stringify({"my_model" : JSON.parse(expected)})

      expect(json).toEqual(expected)

    it "from_json", ->
      json = JSON.stringify({"id": 10, "description": "text"})
      model = MyModel.from_json(json)

      expect(model.id()).toEqual(10)
      expect(model.title()).toEqual("default title")
      expect(model.description()).toEqual("text")

    pending "from_html", ->
      Sirius.Application.adapter = new JQueryAdapter()

      model = MyModel.from_html("#my-model-form")
      console.log(model)
      expect(model.id()).toEqual(1)
      expect(model.title()).toEqual("new title")
      expect(model.description()).toEqual("text...")

  describe "Relations", ->

    p0 = new Person({id: 1})
    p1 = new Person({id: 2})
    n0 = new Name({name: "abc"})
    n1 = new Name({name: "qwe"})
    g0 = new Group({name: "group-0"})
    g1 = new Group({name: "group-1"})
    g2 = new Group({name: "group-2"})

    p0.add_group(g0)
    p0.add_group(g1)
    p1.add_group(g2)
    p0.add_name(n0)

    it "has_*", ->
      expect(p0.attributes.length).toEqual(3)
      expect(p0.group().length).toEqual(2)

      expect(p1.group().length).toEqual(1)

      # feedback
      expect(g0.attributes.length).toEqual(2)

      expect(g0.get('person_id')).toEqual(1)
      expect(g1.get('person_id')).toEqual(1)
      expect(g2.get('person_id')).toEqual(2)

      expect(() ->
        p0.add_name(n1)
      ).toThrowError()

    describe "JSON", ->

      it "to_json", ->
        obj = {"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}],"name":{"name":"abc","person_id":1}};
        json = JSON.parse(p0.to_json())

        expect(obj["id"]).toEqual(json["id"])
        expect(obj["name"]["person_id"]).toEqual(json["name"]["person_id"])
        expect(obj["name"]["name"]).toEqual(json["name"]["name"])
        expect(json["group"].length).toEqual(2)
        expect(obj["group"][0]["name"]).toEqual(json["group"][0]["name"])

      it "from_json", ->
        `var c = function(){console.log(m);}`
        json = JSON.stringify({"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}],"name":{"name":"abc","person_id":1}})

        person = Person.from_json(json, {group: Group, name: Name});

        expect(p0.id()).toEqual(person.id())
        expect(p0.name().name()).toEqual(person.name().name())
        expect(p0.group()[0].person_id()).toEqual(person.group()[0].person_id())
        expect(person.group().length).toEqual(2)

        person = Person.from_json(json)

        expect(p0.id()).toEqual(person.id())
        expect(person.name()["name"]).toEqual(p0.name().name())
        expect(p0.group()[0].person_id()).toEqual(person.group()[0]["person_id"])
        expect(person.group().length).toEqual(2)

  it "guid", ->
    a = new UModel()
    b = new UModel()
    expect(a.id()).not.toBeNull()
    expect(a.id()).not.toEqual(b.id())
