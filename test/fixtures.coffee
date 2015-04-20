class MyModel extends Sirius.BaseModel
  @attrs: ["id", {title: "default title"}, "description"]
  @to:
    id          : tag: "b", class: 'my-model-id'
    title       : tag: "span", class: "my-model-title"

  compare: (other) ->
    @.get("id") == other.get("id")


class MyCustomValidator extends Sirius.Validator
  validate: (value, attrs) ->
    if value?
      if value.length == 3
        true
      else
        @msg = "Value length must be 3"
        false
    else
      @msg = "Null given"
      false

Sirius.BaseModel.register_validator('custom', MyCustomValidator)

class ModelwithValidators extends Sirius.BaseModel
  @attrs: ["id", "title", "description"]
  @validate :
    id:
      presence: true,
      numericality: only_integers: true
      inclusion: within: [1..10]
      validate_with:  (value) ->
        #@msg = ....
        true

    title:
      presence: true
      format: with: /^[A-Z].+/
      length: min: 3, max: 7
      exclusion: within: ["Title"]

    description:
      custom: true
      validate_with: (desc) ->
        if desc == "foo"
          true
        else
          @msg = "Description must be foo"
          false



class Person extends Sirius.BaseModel
  @attrs: ["id"]
  @has_many : ["group"]
  @has_one : ["name"]
  @to:
    group: tag: "p", class: "group"

class Group extends Sirius.BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]
  @to:
    name: tag: "span"

class Name extends Sirius.BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]


class UModel extends Sirius.BaseModel
  @attrs: ["id"]
  @guid_for : "id"


class TodoList extends Sirius.BaseModel
  @attrs: ["title", {completed: false}, "id"]
  @guid_for : "id"
  is_active: () ->
    !@completed()

  is_completed: () ->
    @completed()

#### controllers #######

Controller0 =
  before_action: () ->
    "before"
  after_action: () ->
    "after"
  action: () ->
    "action"

  action0: () ->
    "action0"

  before_action1: () ->
    "before1"

  action1 : () ->
    "action1"

class SkipFieldsModel extends Sirius.BaseModel
  @attrs: ["id"]
  @skip : true














