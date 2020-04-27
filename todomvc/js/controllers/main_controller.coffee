
MainController =
  root: () ->
    Renderer.render(TodoList.all())

  active: () ->
    Renderer.render(TodoList.filter((t) -> t.is_active()))

  completed: () ->
    Renderer.render(TodoList.filter((t) -> t.is_completed()))

  start: () ->
    $.get({
      url: "/js/ejs/todo.ejs",
      success: (tempalte_text) ->
        Template.todo_template = tempalte_text
        view  = new Sirius.View(HtmlElements.todoapp)
        model = new Task()

        Sirius.Materializer.build(view, model)
          .field(HtmlElements.new_todo)
          .to((m) -> m.title)
          .transform((r) -> r.text)
          .run()

        view.on(HtmlElements.new_todo, 'keypress', 'todo:create', model)

        TodoList.add(new Task({title : 'Create a TodoMVC template', completed: true}))
        TodoList.add(new Task(title: 'Rule the web'))
    })


