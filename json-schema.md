%%%
Title = "JavaScript Object Notation (JSON) Schema"
area = "Internet"
workgroup = "Internet Engineering Task Force"

[seriesInfo]
name = "Internet-Draft"
value = "draft-ucarion-00"
stream = "IETF"
status = "standard"

[[author]]
initials = "U."
surname = "Carion"
fullname = "Ulysse Carion"
  [author.address]
  email = "ulysse@ulysse.io"
%%%

.# Abstract

This document describes JavaScript Object Notation (JSON) Schema, a portable
method for describing the format of JSON data, as well as validation errors for
ill-formatted data.

{mainmatter}

# Introduction

JSON Schema is a schema language for JSON data. This document specifies:

* when a JSON object is a correct JSON Schema schema
* when a JSON document is valid with respect to a correct JSON Schema schema
* a standardized form of errors to produce when validating a JSON value

JSON Schema is centered around the question of validating a JSON value (an
"instance") against a JSON object (a "schema"), within the context of a
collection of other schemas (an "evaluation context").

# Conventions

The keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**,
**SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL**, when
they appear in this document, are to be interpreted as described in [@RFC2119].

The terms "absolute-URI" and "URI-reference", when they appear in this document,
are to be understood as they are defined in [@!RFC3986].

The term "JSON Pointer", when it appears in this document, is to be understood
as it is defined in [@RFC6901].

# Terminology

* instance: A JSON value being validated.
* schema: A JSON object describing the form of valid instances.
* evaluation context: A collection of schemas whcih may refer to one another.
* validation error: A JSON object representing a reason why an instance is
  invalid.

# Syntax {#syntax}

This section specifies when a JSON document is a correct schema.

## Keywords {#schema-keywords}

Some member names of a schema are reserved, and carry special meaning. These
member names are called keywords. Correct schemas **MUST** satisfy the following
requirements:

* `id`: If a schema has a member named `id`, its corresponding value **MUST** be
  a JSON string encoding an absolute-URI.
* `definitions`: If a schema has a member named `definitions`, its corresponding
  value **MUST** be a JSON object. The values of this object **MUST** all be
  correct schemas.
* `ref`: If a schema has a member named `ref`, its corresponding value **MUST**
  be a JSON string encoding a URI-reference.
* `type`: If a schema has a member named `type`, its corresponding value
  **MUST** be a JSON string encoding one of the values `null`, `boolean`,
  `number`, or `string`.
* `elements`: If a schema has a member named `elements`, its corresponding value
  **MUST** be a JSON object. This object **MUST** be a correct schema.
* `properties`: If a schema has a member named `properties`, its corresponding
  value **MUST** be a JSON object. The values of this object **MUST** all be
  correct schemas.
* `optionalProperties`: If a schema has a member named `optionalProperties`, its
  corresponding value **MUST** be a JSON object. The values of this object
  **MUST** all be correct schemas.
* `values`: If a schema has a member named `values`, its corresponding value
  **MUST** be a JSON object. This object **MUST** be a correct schema.
* `discriminator`: If a schema has a member named `discriminator`, its
  corresponding value **MUST** be a JSON object. This object **MUST** have
  exactly two members:

  * A member with the name `propertyName`, whose corresponding value **MUST** be
    a JSON string.
  * A member with the name `mapping`, whose corresponding value **MUST** be a
    JSON object. The values of this object **MUST** all be correct schemas. All
    of these schemas **MUST** fall into the "properties" form (see (#forms)),
    and **MUST NOT** have members in `properties` or `optionalProperties` whose
    name has the same value as `propertyName`.

    These restrictions on the values within `mapping` are to prevent ambiguous
    or unsatisfiable schemas.

If a schema has both `properties` and `optionalProperties` members, their values
**MUST NOT** share any member names in common. This is to prevent ambiguous or
unsatisfiable schemas.

## Forms {#forms}

Only certain combinations of schema keywords are correct. These valid
combinations are called "forms". Correct schemas **MUST** fall into exactly one
of the following forms:

* The "empty" form: the schema may have members with the name `id` and/or
  `definitions`, but none of the other keywords listed in (#schema-keywords).
* The "ref" form: the schema may have members with the name `id`, `definitions`,
  and/or `ref`, but none of the other keywords listed in (#schema-keywords).
* The "type" form: the schema may have members with the name `id`,
  `definitions`, and/or `ref`, but none of the other keywords listed in
  (#schema-keywords).
* The "elements" form: the schema may have the members with the name `id`,
  `definitions`, and/or `elements`, but none of the other keywords listed in
  (#schema-keywords).
* The "properties" form: the schema may have the members with the name `id`,
  `definitions`, `properties`, and/or `optionalProperties`, but none of the
  other keywords listed in (#schema-keywords).
* The "values" form: the schema may have the members with the name `id`,
  `definitions`, and/or `values`, but none of the other keywords listed in
  (#schema-keywords).
* The "discriminator" form: the schema may have the members with the name `id`,
  `definitions`, and/or `discriminator`, but none of the other keywords listed
  in (#schema-keywords).

## Evaluation context and reference resolution {#ref-resolution}

An evluation context is a collection of schemas which may refer to one another.
An evaluation context is correct if all of its constituent schemas are correct,
no two constituent schemas have the same `id` value, and no more than one schema
lacks an `id` value.

If a schema is correct and it has a member named `ref`, then this member is said
to be a reference. The reference of a correct schema **MUST** be resolvable.
Reference resolution is defined as follows:

1. By (#schema-keywords), a schema may be contained by another schema. Reference
   resolution uses the "root" of a schema to determine a base URI. The "root" of
   a given schema is the immediate element of an evaluation context which
   contains the given schema.

2. By (#schema-keywords), the value of the reference must be a URI-reference.
   This URI-reference is resolved using the process described in [@!RFC3986] to
   produce a resolved URI. If the root of a schema has a member named `id`, then
   that member's corresponding value shall be used as the base URI.

3. Take the URI from (2), and remove its fragment part, if present.

4. Find the element of the evaluation context which has a member named `id` and
   whose value equals the URI from (3). If there does not exist such a schema,
   then the reference is unresolvable.

5. If URI from (2) has no fragment, then the reference resolves to the schema
   from (4).

6. Otherwise, the schema from (4) must have a member named `definitions`; if it
   does not, then the reference is unresolvable. Furthermore, the `definitions`
   value must have a member whose name equals the fragment of the URI from (2);
   if it does not, then the reference is unresolvable. If it does have such a
   member, then the reference resolves to this member's value.

For example, if an evaluation context contains two schemas:

```json
{
  "id": "http://example.com",
  "ref": "/foo#a"
}
```

```json
{
  "id": "http://example.com/foo",
  "definitions": {
    "a": {
      "ref": "#"
    },
    "b": {
      "id": "http://example.com/bar",
      "ref": "#"
    }
  }
}
```

Then the reference with value `/foo#a` refers to the `a` definition of the
schema with ID `http://example.com/foo`. Both of the references with value `#`
refer the root schema with ID `http://example.com/foo`. The `id` keyword of the
`b` definition is irrelevant, as it occurs outside of a root schema.

As a consequence of this definition, members of the `definitions` of a schema
are impossible to refer to. Implementations **MAY** raise a warning to indicate
this presumably dead code, but **MUST NOT** consider this to be an error.

# Semantics

This section specifies when an instance is valid against a correct schema,
within the context of an evaluation context. This section also specifies a
standardized form of errors to produce when validating an instance.

## Configuration

Users will have different desired behavior with respect to unspecified members
in a schema or instance. Two distinct sets of semantics (one for schemas,
another for instances), determine whether unspecified members are acceptable.

### Strict schema semantics {#strict-schema}

When evaluation is using strict schema semantics, then a correct schema **MUST
NOT** contain members whose names are outside the list of keywords described in
(#schema-keywords). When evaluation is not using strict schema semantics, then a
correct schema **MAY** contain members whose names are outside this list.

Implementations **MAY** allow users to choose whether to use strict schema
semantics. Implementations **SHOULD** document whether they use strict schema
semantics by default.

### Strict instance semantics

See (#eval-props-form) for how strict instance semantics affects whether an
instance is valid with respect to a schema.

Implementations **MAY** allow users to choose whether to use strict instance
semantics. Implementations **SHOULD** document whether they use strict instance
semantics by default.

## Errors

To facilitate consistent validation error handling, this document specifies a
standard error format. Implementations **SHOULD** support producing errors in
this standard form.

The standard error format is a JSON array. The order of this array is not
specified. The elements of this array are JSON objects with up to three members:

* A member with the name `instancePath`, whose value is a JSON string containing
  a JSON Pointer. This JSON Pointer will point to the part of the instance that
  was rejected.
* A member with the name `schemaPath`, whose value is a JSON string containing a
  JSON Pointer. This JSON Pointer will point to the part of the schema that
  rejected the instance.
* A member with the name `schemaURI`, whose value is an absolute-URI. This URI
  will be the `id` value of the root schema of the schema that rejected the
  instance. See (#ref-resolution) for a definition of a schema's root. If the
  root schema lacks an `id` value, then the `schemaURI` member shall be omitted.

The values for `instancePath` and `schemaPath` depend on the form of the schema,
and are described in detail in (#evaluation).

## Evaluation {#evaluation}

Whether an instance is valid against a schema depends upon the form of the
schema. This section describes how each form validates instances.

### Empty form

If a schema is of the "empty" form, then it accepts all instances.

### Ref form

The "ref" form is meant to enable schema re-use.

If a schema is of the "ref" form, then it accepts an instance if and only if the
schema which the `ref` member resolves to accepts the instance. The standard
errors to produce are the same as those that the referent schema produces. The
resolution of a `ref` member is described in (#ref-resolution).

For example, if we evaluate the instance:

```json
"example"
```

Against the schema:

```json
{
  "ref": "http://example.com"
}
```

Within an evaluating context containing the schema:

```json
{
  "id": "http://example.com",
  "type": "number"
}
```

Then the standard errors are:

```json
[
  {
    "instancePath": "",
    "schemaPath": "/type",
    "schemaURI": "http://example.com"
  }
]
```

See (#eval-type-form) for how the `type` member produces errors, as the errors
in the example above compose upon `type` errors.

### Type form {eval-type-form}

The "type" form is meant to describe the primitive data types of JSON.

If a schema is of the "type" form, then:

* If the value of the `type` member is `null`, then the instance is accepted if
  it equals `null`.
* If the value of the `type` member is `boolean`, then the instance is accepted
  if it equals `true` or `false`.
* If the value of the `type` member is `number`, then the instance is accepted
  if it is a JSON number.
* If the value of the `type` member is `string`, then the instance is accepted
  if it is a JSON string.

If the instance is not accepted, the the standard error for this case shall have
an `instancePath` pointing to the instance, and a `schemaPath` pointing to the
`type` member.

For example, if we evaluate the instance:

```json
"example"
```

Against the schema:

```json
{ "type": "number" }
```

Then a standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/type" }
]
```

### Elements form

The "elements" form is meant to describe JSON arrays representing homogeneous
data. When a schema is of the "elements" form, it validates:

* that the instance is an array, and
* that all of the elements of the array are of the same type

If a schema is of the "elements" form, then:

1. If the instance is not a JSON array, then the instance is rejected. The
   standard error shall have an `instancePath` pointing to the instance, and a
   `schemaPath` pointing to the `elements` member.
2. Otherwise, the instance is accepted if each element of the instance is
   accepted by the value of the `elements` member. The standard error shall be
   the concatenation of the standard errors from evaluating each element of the
   instance against the value of the `elements` member.

For example, if we have the schema:

```json
{
  "elements": {
    "type": "number"
  }
}
```

Then if we evaluate the instance:

```json
"example"
```

Against this schema, a standard error are:

```json
[
  { "instancePath": "", "schemaPath": "/elements" }
]
```

If instead we evaluate the instance:

```json
[1, 2, "foo", 3, "bar"]
```

The standard errors are:

```json
[
  { "instancePath": "/2", "schemaPath": "/elements/type" },
  { "instancePath": "/4", "schemaPath": "/elements/type" },
]
```

### Properties form {#eval-props-form}

The "properties" form is meant to describe JSON objects being used in a fashion
similar to structs in C-like languages. When a schema is of the "properties"
form, it validates:

* that the instance is an object,
* that the instance has a set of required properties, each satisfying their own
  respective schema, and
* that the instance may have a set of optional properties that, if present in
  the instance, satisfy their own respective schema.

If a schema is of the "properties" form, then:

1. If the instance is not a JSON object, then the instance is rejected.

   The standard error for this case has an `instancePath` pointing to the
   instance. If the schem has a `properties` member, then the `schemaPath` of
   the error shall point to the `properties` member. Otherwise, `schemaPath`
   shall point to the `optionalProperties` member.

2. If the instance is a JSON object, and the schema has a `properties` member,
   then for each member name of the `properties` of the schema, a member of the
   same name must appear in the instance. Otherwise, the instance is rejected.

   The standard error for this case has an `instancePath` pointing to the
   instance, and a `schemaPath` pointing to the member of `properties` whose
   name lacks a counterpart in the instance.

3. If the instance is a JSON object, then for each member of the instance, find
   a member of the same name in the `properties` or `optionalProperties` of the
   schema.

   * If no such member in the `properties` or `optionalProperties` exists, and
     validation is using strict instance semantics, then the instance is
     rejected.

     The standard error for this case has an `instancePath` pointing to the
     member of the instance lacking a counterpart in the schema, and a
     `schemaPath` pointing to the schema.

   * If such a member in the `properties` or `optionalProperties` does exist,
     then the value of the member from the instance must be accepted by the
     value of the corresponding member from the schema. Otherwise, the instance
     is rejected.

     The standard error for this case is the concatenation of the errors from
     evaluating the member of the instance against the member of the schema.

An instance may have errors arising from both (2) and (3). In this case, the
standard errors should be concatenated together.

For example, if we have the schema:

```json
{
  "properties": {
    "a": { "type": "string" },
    "b": { "type": "string" }
  },
  "optionalProperties": {
    "c": { "type": "string" },
    "d": { "type": "string" }
  }
}
```

Then if we evaluate the instance:

```json
"example"
```

Against this schema, then the standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/properties" }
]
```

If instead we evalute the instance:

```json
{ "b": 3, "c": 3 }
```

The standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/properties/a" },
  { "instancePath": "/b", "schemaPath": "/properties/b/type" },
  { "instancePath": "/c", "schemaPath": "/optionalProperties/c/type" }
]
```

### Values form

The "values" form is meant to describe JSON objects being used as an associative
array mapping arbitrary strings to values all of the same type. When a schema is
of the "properties" form, it validates:

* that the instance is an object, and
* that the values of the instance all satisfy the same schema.

If a schema is of the "values" form, then:

1. If the instance is not a JSON object, then the instance is rejected. The
   standard error shall have an `instancePath` pointing to the instance, and a
   `schemaPath` pointing to the `values` member.

2. Otherwise, the instance is accepted if the value of each member of the
   instance is accepted by the value of the `values` member. The standard error
   shall be the concatenation of the standard errors from evaluating the value
   of each member of the instance against the value of the `values` member.

For example, if we have the schema:

```json
{
  "values": {
    "type": "number"
  }
}
```

Then if we evaluate the instance:

```json
"example"
```

Against this schema, the standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/values" }
]
```

If instead we evaluate the instance:

```json
{ "a": 1, "b": 2, "c": "foo", "d": 3, "e": "bar"}
```

The standard errors are:

```json
[
  { "instancePath": "/c", "schemaPath": "/values/type" },
  { "instancePath": "/e", "schemaPath": "/values/type" }
]
```

### Discriminator form

The "discriminator" form is meant to describe JSON objects being used in a
fashion similar to a discriminated union construct in C-like languages. When a
schema is of the "disciminator" type, it validates:

* that the instance is an object,
* that the instance has a particular "disciminator" property,
* that this "discriminator" value is a string within a set of valid values, and
* that the instance satisfies another schema, where this other schema is chosen
  based on the value of the "discriminator" property.

If a schema is of the "disciminator" form, then:

1. If the instance is not a JSON object, then the instance is rejected. The
   standard error shall have an `instancePath` pointing to the instance, and a
   `schemaPath` pointing to the `discriminator` member.

2. If the instance is a JSON object and lacks a member whose name equals the
   `propertyName` value of the `discriminator` of the schema, then the instance
   is rejected.

   The standard error to produce in this case has an `instancePath` pointing to
   the instance, and a `schemaPath` pointing to the `propertyName` member of the
   `disciminator` member of the schema.

3. If the instance is a JSON object and has a member whose name equals the
   `propertyName` value of the `discriminator` of the schema, but that member's
   value is not equal to any of the member names in the `mapping` of the
   `discriminator`, then the instance is rejected.

   The standard error to produce in this case has an `instancePath` pointing to
   the member of the instance corresponding to `propertyName`, and a
   `schemaPath` pointing to the `mapping` member of the `discriminator` member
   of the schema.

4. If the instance is a JSON object and has a member whose name equals the
   `propertyName` value of the `discriminator` of the schema, and that member's
   value is equal to one of the member names in the `mapping` of the
   `discriminator`, then the instance must satisfy this corresponding schema in
   `mapping`. Otherwise, the instance is rejected.

   The standard errors to produce in this case are those produced by evaluating
   the instance against the schema within the `mapping`.

For example, if we have the schema:

```json
{
  "discriminator": {
    "propertyName": "version",
    "mapping": {
      "v1": {
        "properties": {
          "a": { "type": "number" }
        }
      },
      "v2": {
        "properties": {
          "a": { "type": "string" }
        }
      }
    }
  }
}
```

Then if we evaluate the instance:

```json
"example"
```

Against this schema, the standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/discriminator" }
]
```

If we instead evaluate the instance:

```json
{}
```

Then the standard errors are:

```json
[
  { "instancePath": "", "schemaPath": "/discriminator/propertyName" }
]
```

If we instead evaluate the instance:

```json
{
  "version": "v3"
}
```

Then the standard errors are:

```json
[
  { "instancePath": "/version", "schemaPath": "/discriminator/mapping" }
]
```

Finally, if the instance evaluated were:

```json
{
  "version": "v2",
  "a": 3
}
```

Then the standard errors are:

```json
[
  { "instancePath": "/a",
    "schemaPath": "/discriminator/mapping/v2/properties/a/type" }
]
```

# IANA Considerations

No IANA considerations.

# Security Considerations

Implementations of JSON Schema will necessarily be manipulating JSON data.
Therefore, the security considerations of [@!RFC8259] are all relevant here.

Implementations which evaluate user-inputted schemas **SHOULD** implement
mechanisms to detect, and abort, circular references which might cause a naive
implementation to go into an infinite loop. Without such mechanisms,
implementations may be vulnerable to denial-of-service attacks.

# Acknowledgments

Thanks to Gary Court, Francis Galiegue, Kris Zyp, Geraint Luff, Jason
Desrosiers, Daniel Perrett, Erik Wilde, Ben Hutton, Evgeny Poberezkin, Brad
Bowman, Gowry Sankar, Donald Pipowitch, Dave Finlay, Denis Laxalde, Henry
Andrews, and Austin Wright for their work on the initial drafts of JSON Schema.

{backmatter}
