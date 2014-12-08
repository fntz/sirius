describe "View2ObjectProperty", ->
  element = ".view2object span"
  object = {
    id: {
      num: ""
    }
  }
  view = new Sirius.View(element)
  view.bind(object, "id.num", {transform: (x) -> "#{x}!!!"})

  beforeEach (done) ->
    object.id.num = "new"
    done()

  it "should change element content when bind with property", ->
    expect($(element).text()).toEqual("new!!!")




