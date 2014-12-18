"use strict"

class TodoList extends Sirius.BaseModel
  @attrs: ["title", {completed: false}, "id"]

  constructor: (obj = {}) ->
    super(obj)
    @_id = "todo-#{Math.random().toString(36).substring(7)}"

  is_active: () -> !@completed()
  
  is_completed: () -> @completed()

  after_update: (attribute, newvalue, oldvalue) ->
    if attribute == "completed" || newvalue == true
      Sirius.Application.get_adapter().and_then((adapter) -> adapter.fire(document, "collection:length"))

  compare: (other) -> other.id() == @id()

Renderer =
  todo_template: new EJS({url: 'js/todo.ejs'})
  view: new Sirius.View("#todo-list")
  clear_view: new Sirius.View("#clear-completed", (size) -> "Clear completed (#{size})")

  render: (todo_list) ->
    @view.render().clear()
    for todo in todo_list
      @append(todo)



  append: (todo) ->
    template = @todo_template.render({todo: todo})
    @view.render(template).append()
    todo_view = new Sirius.View("li\##{todo.id()}")
    todo.bind(todo_view, {
      transform:
        mark_as_completed: (t) -> if t then "completed" else ""
    })
    todo_view.bind(todo)

    todo_view.on('div', 'dblclick', (x) ->
      todo_view.render("editing").swap('class')
    )
    return

  clear: (size) ->
    if size != 0
      @clear_view.render(size).swap()
    else
      @clear_view.render().clear()


Todos = new Sirius.Collection(TodoList)

Todos.subscribe('add', (todo) -> Renderer.append(todo))
Todos.subscribe('remove', (todo) -> $("\##{todo.id()}").remove())



#------------------ Controllers -----------------#

MainController =
  root: () ->
    Renderer.render(Todos.all())

  active: () ->
    Renderer.render(Todos.filter((t) -> t.is_active()))

  completed: () ->
    Renderer.render(Todos.filter((t) -> t.is_completed()))

  start: () ->
    view  = new Sirius.View("#todoapp")
    model = new TodoList()
    view.bind2(model)
    view.on("#new-todo", "keypress", "todo:create", model)

    length_view = new Sirius.View("#todo-count strong")
    length_view.bind(Todos, 'length')

    footer = new Sirius.View("#footer")
    footer.bind(Todos, 'length', {
      to: 'class'
      transform: (x) ->
        if x == 0
          "hidden"
        else
          ""
    })

    Todos.add(new TodoList({title : "Create a TodoMVC template", completed: true}))
    Todos.add(new TodoList(title: "Rule the web"))


TodoController =

  is_enter: (custom_event, original_event) ->
    return true if original_event.which == 13
    false

  create: (custom_event, original_event, model) ->
    todo = new TodoList(title: model.title())
    Todos.add(todo)
    model.title("")


  mark_all: (e, state) ->
    if state == 'completed'
      Todos.filter((t) -> t.is_completed()).map((t) -> t.completed(false))
    else
      Todos.filter((t) -> t.is_active()).map((t) -> t.completed(true))

    $("#toggle-all").toggleClass('completed')


  destroy: (e, id) ->
    todo = Todos.filter((t) -> t.id() == id)[0]
    Todos.remove(todo)

BottomController =
  change: () ->
    Renderer.clear(Todos.filter((t) -> t.is_completed()).length)


  clear: () ->
    Todos.filter((t) -> t.is_completed()).map((t) -> Todos.remove(t))
    Renderer.clear(0)


# ----------------------- Routing ----------------- #

routes = 
  "/"               : {controller: MainController, action: "root"}
  "/active"        :  {controller: MainController, action: "active"}
  "/completed"     :  {controller: MainController, action: "completed"}
  "application:run" : {controller: MainController, action: "start"}
  "todo:create" :     {controller: TodoController, action: "create", guard: "is_enter"}
  "click #toggle-all"     : {controller: TodoController, action: "mark_all", data: 'class'}
  "collection:length" : {controller: BottomController, action: "change"}
  "click button.destroy"  : {controller: TodoController, action: "destroy", data: "data-id"}
  "click #clear-completed": {controller: BottomController, action: "clear"}

# ----------------------- Start -------------------- #

$ ->
  Sirius.Application.run
    route   : routes
    adapter : new JQueryAdapter()
    class_name_for_active_link: 'selected'
    log: false







