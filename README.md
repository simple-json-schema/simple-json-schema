# Simple JSON Schema

> Note: this project is under active development, and is in a "pre-alpha" state.

The **Simplify JSON Schema** project is an effort to help simplify JSON Schema
toward something that's more useful and understandable to users. Simplify JSON
Schema is a pair of specs:

* **Safe JSON Schema** is a subset of JSON Schema draft-07 which is
  well-defined, useful, and reliably implemented correctly. All JSON Schema
  implementations are also Safe JSON Schema implementations.

* **Simple JSON Schema** is the proposed finalized version of JSON Schema. It
  maps closely to Safe JSON Schema, but makes a few backwards-incompatible
  changes that make JSON Schema a much more effective schema language.

Safe JSON Schema is meant to be a transitional springboard into Simple JSON
Schema -- a program can automatically convert Simple JSON Schema into Safe JSON
Schema and vice-versa.

## Simple JSON Schema

> Simple JSON Schema is what the Simplify JSON Schema project proposes should be
> the finalized version of JSON Schema. This section is a five-minute
> description of how Simple JSON Schema works.

### Primitive data types

To validate primitive data types, like `null`, booleans, numbers, or strings,
you can use the `type` keyword. For example,

```json
{ "type": "string" }
```

Would accept `"foo"`, but not `3.14` or `false`.

### Arrays

To validate arrays, you can use the `elements` keyword, which does two things:

1. Check that the input is an array, and
2. Check that each element of the input is valid against a schema.

For example,

```json
{
  "elements": { "type": "string" }
}
```

Would accept `["foo", "bar"]` or `[]`, but not `3.14` or `["foo", 3.14]`.

### Objects

There are three major ways people use JSON objects:

1. As *structs*, where you have a set of properties (possibly some of them
   optional) whose names you know in advance. Each of those properties needs to
   satisfy a different schema.
2. As *dictionaries*, where you don't know the keys in advance, but you do know
   that all the values have to satisfy the same schema. For instance, the keys
   might be random user IDs that you can't anticipate in advance, but the values
   all have to be user profiles.
3. As *discriminated unions*, aka *tagged unions*, where you look at a
   particular property, and based on its value you know what sort of schema the
   data should look like.

Each of these three ways of dealing with objects has their own formats.

#### Structs

To validate struct-like objects, you can use the `properties` and
`optionalProperties` keywords, which do three things:

1. Check that the input is an object, and
2. For each key in `properties`, check that the property exists in the input,
   and that it satisfies the schema for that property.
3. For each key in `optionalProperties`, *if* the property exists in the input,
   then check that the value is valid against the schema for that optional
   property. If the property doesn't exist in the input, that's ok.

For example,

```json
{
  "properties": {
    "a": { "type": "string" }
  },
  "optionalProperties": {
    "b": { "type": "number" }
  }
}
```

Would accept `{"a": "foo"}` and `{"a": "foo", "b": 3.14}`, but not `3.14`, `{}`,
`{"a": false}` or `{"a": "foo", b: false}`.

#### Dictionaries

To validate dictionary-like objects, you can use the `values` keyword, which
does two things:

1. Check that the input is an object, and
2. Check that each value of the object is valid against a schema.

For example,

```json
{
  "values": { "type": "string" }
}
```

Would accept `{"a": "foo", "b": "bar"}` and `{}`, but not `3.14` or `{"a":
"foo", "b": 3.14}`.

#### Discriminated Unions

To validate discriminated-union-like objects, you can use the `discriminator`
keyword, which does three things:

1. Check that the input is an object,
2. Check that the input has a property you name using `properyName`, and that
   the value for that property is a string, and
3. Based on the value of that string, check that the input matches the
   corresponding schema in `mapping`. If the string isn't one of the keys in
   `mapping`, then the input is considered invalid.

For example, if you want to discriminate using `version`, where if `version`
equals `"alpha"` you check that `a` is a number, but if `version` is instead
`"beta"` you check that `a` is a string, you can do:

```json
{
  "discriminator": {
    "propertyName": "version",
    "mapping": {
      "alpha": {
        "properties": {
          "a": { "type": "number" }
        }
      },
      "beta": {
        "properties": {
          "a": { "type": "string" }
        }
      }
    }
  }
}
```

This would accept:

* `{"version": "alpha", "a": 3.14}`
* `{"version": "beta", "a": "foo"}`

But not

* `3.14`
* `{}`
* `{"version": "gamma"}`
* `{"version": "alpha", "a": "foo"}`
* `{"version": "beta", "a", 3.14}`

### Re-using schemas

Oftentimes you'll find yourself using the same schema again and again. You can
re-use schemas by putting a schema inside `definitions`, and then referencing
that schema using `ref`. For example:

```json
{
  "definitions": {
    "example": { "type": "string" }
  },
  "properties": {
    "a": { "ref": "#example" },
    "b": { "ref": "#example" }
  }
}
```

Would check that the input is an object with properties `a` and `b`, both of
them strings.

All validators support taking a bundle of schemas, which is just an array of
schemas, each with a different ID. The ID of a schema is just the value of its
`id` keyword. You can then cross-reference between schemas by their ID.

For example, if you split out a reusable schema for users, then you can
reference that schema to create, in this case, a dictionary of arrays of users:

```json
[
  {
    "id": "http://schemas.example.com/user.json",
    "properties": {
      "userId": { "type": "string" },
      "name": { "type": "string" },
      "isAdmin": { "type": "boolean" }
    }
  },
  {
    "values": {
      "elements": {
        "ref": "http://schemas.example.com/user.json"
      }
    }
  }
]
```

This is sort of a more advanced feature. It's mainly useful once you find
yourself writing a lot schemas, and you want to standardize how everyone in the
organization represents a user.

### Validator options

All validators have two options that let you control what should happen with
"unexpected", but not necessarily "wrong", data:

* *Strict schema mode*, which is on by default, makes it so that if a schema has
  unexpected keywords (i.e. keywords not perscribed by this document), then the
  schema is considered invalid.

  This is on by default because it ensures you don't accidentally misspell a
  keyword. A misspelled keyword has no effect, and so you might accidentally let
  bad data through.

  Sometimes, you want to put extra data in your schemas, such as nonstandard
  keywords or extra metadata. In that case, you should disable strict schema
  mode, but be more careful about the possibility of spelling keywords
  incorrectly.

* *Strict instance mode*, which is also on by default, makes it so that if a
  schema uses `properties` and `optionalProperties`, and the input has
  properties not mentioned by either of those keywords, then the input is
  considered invalid.

  This is on by default because in many cases, sending unplanned data is a
  mistake, and may pollute the ultimate destination of the data.

  Sometimes, you do want to let unmentioned keywords through. In that case, you
  can simply disable strict instance mode.

## Safe JSON Schema

> This section is a five-minute description of Safe JSON Schema, an
> interoperable subset of JSON Schema draft-07 that is conceptually similar to
> Simple JSON Schema.

Safe JSON Schema works based on the concept of *instances*, which are pieces of
JSON data you want to validate, and *schemas*, which are JSON documents
describing what form your instances ought to take. A *validator* takes schemas,
and reports whether instances match that schema or not.

Schemas are JSON objects, and can take on one of four forms:

* The "empty" form, which accepts all inputs.

  Schemas of this form have no keywords inside them.

* The "type" form, which you can use to validate primitive data.

  Schemas of this form have only one keyword, `type`, whose values can be
  `"null"`, `"boolean"`, `"number"`, or `"string"`.

  Here's some examples:

  | Valid?                | `null` | `true` | `3.14` | `"foo"` |
  | --------------------- | ------ | ------ | ------ | ------- |
  | `{"type": "null"}`    | Yes    | No     | No     | No      |
  | `{"type": "boolean"}` | No     | Yes    | No     | No      |
  | `{"type": "number"}`  | No     | No     | Yes    | No      |
  | `{"type": "string"}`  | No     | No     | No     | Yes     |

* The "items" form, which you can use to validate that data is an array, and
  that the elements of that array all match a particular schema.

  Schemas of this form have two keywords: `type`, whose value must be `"array"`,
  and `items`, whose value must be a schema.

  Here's some examples:

  | Valid?                                           | `null` | `[]` | `["foo", 3.14]` | `["foo", "bar"]` |
  | ------------------------------------------------ | ------ | ---- | --------------- | ---------------- |
  | `{"type": "array", "items": {}}`                 | No     | Yes  | Yes             | Yes              |
  | `{"type": "array", "items": {"type": "string"}}` | No     | Yes  | No              | Yes              |

* The "struct" form, which you can use to validate struct-like objects, by
  specifying what schemas different properties should follow, and what
  properties required.

  Schemas of this form have two mandatory keywords: `type`, whose value must be
  `"object"`, and `properties` whose value must be an object. The values of that
  object must all be schemas. Optionally, schemas may have a `required` keyword,
  whose value must be an array, and elements of that array must be keys of the
  `properties` object.

  Validators will accept the instance if all of the following are true:

  1. The instance is an object.
  2. If the instance has a key named in the schema's `properties`, that the
     instance's value for that key is valid against the schema for that key --
     in other words, that `instance[key]` is valid against
     `schema.properties[key]`.
  3. If the schema has `required` properties, that the instance has all of the
     keys named in `required`.

  For example,

  ```json
  {
    "type": "object",
    "properties": {}
  }
  ```

  Would reject `null`, but accept `{}`, `{"a": 3.14}`, `{"a": "foo"}`, and
  `{"a": "foo", "b": 3.14}`. Next consider:

  ```json
  {
    "type": "object",
    "properties": {
      "a": { "type": "string" },
      "b": { "type": "number" }
    }
  }
  ```

  Would reject `null` and `{"a": 3.14}`, but accept `{}`, `{"a": "foo"}`, and
  `{"a": "foo", "b": 3.14}`. Finally:

  ```json
  {
    "type": "object",
    "properties": {
      "a": { "type": "string" },
      "b": { "type": "number" }
    },
    "required": ["a", "b"]
  }
  ```

  Would reject `null`, `{"a": 3.14}`, and `{"a": "foo"}`, but accept `{"a":
  "foo", "b": 3.14}`.

* The "dictionary" form, which you can use to validate dictionary-like objects,
  where you don't know the keys in advance but you do know what all the values
  must be like.

  Schemas of this form have two keywords: `type`, whose value must be
  `"object"`, and `additionalProperties`, whose value must be a schema.

  Validators will accept the instance if the instance is an object, and all
  values of the instance are valid against the value of `additonalProperties`.

  For example,

  ```json
  {
    "type": "object",
    "additionalProperties": {}
  }
  ```

  Would reject `null`, but accept `{}`, `{"a": "foo"}`, and `{"a": "foo", "b":
  3.14}`. Whereas:

  ```json
  {
    "type": "object",
    "additionalProperties": { "type": "string" },
  }
  ```

  Would reject `null` and `{"a": "foo", "b": 3.14}`, but accept `{}` and `{"a":
  "foo"}`.

That's all there is to Safe JSON Schema. It's intentionally quite limited,
because venturing very far beyond this subset will frequently lead to
inconsistencies between implementations.
