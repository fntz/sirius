describe "View2Model", ->

  element = "#view2model_spec"
  field = "input[name='model-name']"

  it "fail when model 'to' attribute was not found", ->
    model = new MyTestView2ModelSpecModel()
    view = new Sirius.View(element)
    pipe = Sirius.Transformer.draw({
      field: {
      }
    })

    expect(() -> view.pipe(model, pipe)).toThrow()



  it "text to model attribute", ->
    model = new MyTestView2ModelSpecModel()
    view = new Sirius.View(element)
    pipe = Sirius.Transformer.draw({
      "#{field}": {
        "to": "name",
        "from": "text"
      }
    })


    view.pipe(model, pipe)

    set_value("#{element} #{field}", "foo")

    _element = document.querySelector("#{element} #{field}")

    event = new Event('input', {
      'bubbles': true,
      'cancelable': true
    })

    _element.dispatchEvent(event)


    expect(model.name()).toEqual("foo")


  describe "html attribute to model attribute", ->
    model = new MyTestView2ModelSpecModel()
    view = new Sirius.View(element)
    pipe = Sirius.Transformer.draw({
      "#{field}": {
        "to": "name",
        "from": "data-name"
      }
    })


    view.pipe(model, pipe)
    adapter.set_attr("#{element} #{field}", "data-name", "foo")
    _element = document.querySelector("#{element} #{field}")

    event = new Event('input', {
      'bubbles': true,
      'cancelable': true
    })

    _element.dispatchEvent(event)
#    expect(model.name()).toEqual("foo")


