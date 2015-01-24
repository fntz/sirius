describe "Collections", ->

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

    mc.remove(model)

    z = [{"id":100,"title":"default title","description":null}][0]
    j = JSON.parse(mc.to_json())

    expect(j['id']).toEqual(z['id'])
    expect(j['title']).toEqual(z['title'])
    expect(j['description']).toEqual(z['description'])

    mc.from_json(mc.to_json())

    expect(mc.size() == 2)
    expect(mc.first().compare(mc.last())).toBeTruthy()

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


  pending "sync"
