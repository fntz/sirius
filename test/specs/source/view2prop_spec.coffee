describe "View2ObjectProperty", ->
  adapter = if JQueryAdapter?
    new JQueryAdapter()
  else if PrototypeAdapter?
    new PrototypeAdapter()
  else
    new VanillaJsAdapter()

  element = ".view2object span"
  object = {
    id: {
      num: ""
    }
  }
  Sirius.Application.adapter = adapter
  view = new Sirius.View(element)
  view.bind(object, "id.num", {transform: (x) -> "#{x}!!!"})

  beforeEach (done) ->
    object.id.num = "new"
    done()

  it "should change element content when bind with property", ->
    expect(adapter.text(element)).toEqual("new!!!")





