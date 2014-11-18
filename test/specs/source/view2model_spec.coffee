describe "View2Model", ->
  `var c = function(m){console.log(m);};`
  Sirius.Application.adapter = new JQueryAdapter()

  describe "text to attribute", ->
    form = "form.my-form"
    formView = new Sirius.View(form)
    myModel = new MyModel()




  describe "attribute view to attribute model", ->


