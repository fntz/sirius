class MyModel extends BaseModel
  @attrs: ["id", {title: "default title"}, "description"]
  @to:
    id          : tag: "b", class: 'my-model-id'
    title       : tag: "span", class: "my-model-title"

class ModelwithValidators extends BaseModel
  @attrs: ["id", {title: "t"}, "description"]
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
      exclusion: ["title"]


class Person extends BaseModel
  @attrs: ["id"]
  @has_many : ["group"]
  @has_one : ["name"]
  @to:
    group: tag: "p", class: "group"

class Group extends BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]
  @to:
    name: tag: "span"

class Name extends BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]


class UModel extends BaseModel
  @attrs: ["id"]
  @guid_for : "id"

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
















