
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

        transformer = {
          "#{HtmlElements.new_todo}": {
            to: 'title'
          }
        }

        view.bind(model, transformer)

        view.on(HtmlElements.new_todo, 'keypress', 'todo:create', model)

        TodoList.add(new Task({title : 'Create a TodoMVC template', completed: true}))
        TodoList.add(new Task(title: 'Rule the web'))
    })


