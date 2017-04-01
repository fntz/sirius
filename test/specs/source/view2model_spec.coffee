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

    t = "foo"
    input_text("#{element} #{field}", t)
    expect(model.name()).toEqual(t)


