"use strict"
`var c = function(m){console.log(m);};`


class TodoList extends Sirius.BaseModel
  @attrs: ["title", {completed: false}, "id"]

  constructor: (obj = {}) ->
    super(obj)
    @_id = "todo-#{Math.random().toString(36).substring(7)}"

  is_active: () ->
    !@completed()
  
  is_completed: () -> 
    @completed()

Todos = new Sirius.Collection(TodoList, [])
Todos.add(new TodoList({title : "Create a TodoMVC template", completed : true}))
Todos.add(new TodoList(title: "Rule the web"))


Renderer =
  template: new EJS({url: 'js/todos.ejs'})
  todo_template: new EJS({url: 'js/todo.ejs'})
  view: new Sirius.View("#todo-list")
  render: (data = []) ->
    todos = for t in data 
      klass =  if t.get("completed") 
                  "completed" 
                else 
                  ""
      {"class_name": klass, "title": t.get("title"), id: t.get("id")}
    

    template = @template.render({todos: todos})
    $("#todo-list").html("").html(template) 

  add: (todo) ->
    c("get id: #{todo.id()}")
    template = @todo_template.render({todo: todo})
    @view.render(template).append()
    todo_view = new Sirius.View("li\##{todo.id()}")
    todo_view.bind(todo)
    todo.bind(todo_view, {
      transform: (t) ->
        if t
          "completed"
        else
          ""
    })

#------------------ Controllers -----------------#

MainController =
  root: () ->
    c(1)

  active: () ->
    Renderer.render(Todos.filter((t) -> t.is_active()))
  
  completed: () ->
    Renderer.render(Todos.filter((t) -> t.is_completed()))

  start: () ->
    view  = new Sirius.View("#todoapp")
    model = new TodoList()
    view.bind2(model)
    view.on("#new-todo", "keypress", "todo:create", model)

  click: () ->
    c(Todos.all())

TodoController =
  is_enter: (custom_event, original_event) ->
    return true if original_event.which == 13
    false

  create: (custom_event, original_event, model) ->
    todo = model.clone()
    Todos.add(todo)
    model.title("")
    c("id: #{todo.id()} and #{model.id()}")
    Renderer.add(todo)
    # todo bind with view

  mark: () ->
    c "mark"


TodoController =
  is_enter: (custom_event, original_event) ->
    return true if original_event.which == 13
    false

  create: (custom_event, original_event, model) ->
    todo = model.clone()
    Todos.add(todo)
    model.title("")
    Renderer.add(todo)
    # todo bind with view

  mark: () ->
    c "mark"


# ----------------------- Routing ----------------- #

routes = 
  "/"               : {controller: MainController, action: "root"}
  "/active"        :  {controller: MainController, action: "active"}
  "/completed"     :  {controller: MainController, action: "completed"}
  "application:run" : {controller: MainController, action: "start"}
  "todo:create" :     {controller: TodoController, action: "create", guard: "is_enter"}
  "click #btn" : {controller: MainController, action: "click"}
 # "click button.destroy"  : {controller: EventController, action: "destroy", after: "update_footer", data: "data-id"}
 # "click li input.toggle" : {controller: EventController, action: "mark", after: "update_footer", data: "data-id"}
 # "click #toggle-all"     : {controller: EventController, action: "mark_all", after: "update_footer", data: "class"}
 # "keypress #new-todo"    : {controller: EventController, action: "new_todo", guard: "is_enter", after: "update_footer"}
 # "dblclick li": {controller: EventController, action: "edit"}
 # "keypress input.edit": {controller: EventController, action: "update", data: "data-id", guard: "is_enter"}
 # "click #clear-completed": {controller: EventController, action: "clear", after: "update_footer"}

# ----------------------- Start -------------------- #

$ ->
  app = Sirius.Application.run
    route   : routes
    adapter : new JQueryAdapter()







