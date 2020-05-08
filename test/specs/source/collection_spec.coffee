describe "Collections", ->

  it "fail when index field are not exist", ->
    expect(() ->
      new Sirius.Collection(MyModel, {index: ["foo"]})
    ).toThrowError()

  it "fail when we try to add incorrect model", ->
    collection = new Sirius.Collection(MyModel)

    expect(() ->
      collection.add("test")
    ).toThrowError("Require 'MyModel', but given 'String'")

    expect(() -> collection.add(new MyModel0()))
      .toThrowError("Require 'MyModel', but given 'MyModel0'")

    expect( () -> collection.add(null))
      .toThrowError("'MyModel' should not be null")

  it "fails with subscribe", ->
    collection = new Sirius.Collection(MyModel)
    expect(() ->
      collection.subscribe("boom", "asd")
    ).toThrowError()

    expect(() ->
      collection.subscribe("add", 1)
    ).toThrowError()


  it "subscribe checks", ->
    is_remove_called = false
    is_add_called = true
    collection = new Sirius.Collection(MyModel)
    collection.subscribe('add', (e) -> is_add_called = true)
    collection.subscribe('remove', (e) -> is_remove_called = true)

    m = new MyModel()
    collection.add(m)
    collection.remove(m)

    expect(is_add_called).toBeTrue()
    expect(is_remove_called).toBeTrue()


  it "base methods", ->
    model = new MyModel({id: 10})

    monitor = false
    options =
      on_add: (model) ->
        if !monitor
          expect(model.id()).toEqual(10)
          monitor = true

      on_remove: (model) ->
        expect(model.id()).toEqual(10)

    mc = new Sirius.Collection(MyModel, [], options)

    expect(mc.size()).toEqual(0)
    expect(mc.length).toEqual(0)
    expect(mc.find("id", 10)).toBeNull()
    expect(mc.find_all("id", 10)).toEqual([])

    mc.add(model)

    expect(mc.size()).toEqual(1)
    expect(mc.find("id", 10)).toEqual(model)

    mc.push(new MyModel({"id": 100}))

    expect(mc.size()).toEqual(2)
    expect(mc.find("id", 10)).toEqual(model)
    expect(mc.find_all("id", 100).length).toEqual(1)

    expect(mc.index(model)).toEqual(0)
    expect(mc.filter((m) -> m.get("id") > 1 ).length).toEqual(2)
    expect(mc.filter((m) -> m.get("id") > 10 ).length).toEqual(1)
    expect(mc.last().get("id")).toEqual(100)

    each_result = []
    mc.each ((x) -> each_result.push(x.id()))
    expect(each_result.length).not.toEqual(0)


    mc.remove(model)

    z = [{"id":100,"title":"default title","description":null}][0]
    j = JSON.parse(mc.to_json())[0]

    expect(j['id']).toEqual(z['id'])
    expect(j['title']).toEqual(z['title'])
    expect(j['description']).toEqual(z['description'])

    mc.clear()

    expect(mc.size() == 0).toBeTruthy()

    for z in [1..10]
      model = new MyModel({id: z})
      mc.add(model)

    expect(mc.size() == 10).toBeTruthy()

    mc0 = mc.collect((m) -> m.id() + 1)
    expect(mc0[0] == 2).toBeTruthy()

    e = mc.takeFirst((f) -> f.id() == 3)
    expect(e.id() == 3).toBeTruthy()

