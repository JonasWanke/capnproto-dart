# This file contains annotations that are recognized by the capnpc-dart code generator.
#
# To use this file, you will need to make sure that it is included in the directories
# searched by `capnp compile`. An easy way to do that is to copy it into your project
# alongside your own schema files.

@0x815ae359c5b49ad5;

annotation name @0xec209b3bbf6afb0f (field, struct, enum, enumerant) :Text;
# Rename something in the generated code. The value that you specify in this
# annotation should follow Cap'n Proto capitalization conventions. So, for example,
# a struct should use UpperCamelCase capitalization like `StructFoo`, even though
# that will get translated to a `struct_foo` module in the generated Dart code.
# TODO: remove capitalization note?
#
# TODO: support annotating more kinds of things with this.

annotation nullable @0x8f48ef3fdb930cd2 (field) :Void;
# Make the generated getters return `T?` instead of `T`. Supported on pointer
# types (e.g., structs, lists, texts, and blobs).
#
# Cap'n Proto pointer types are nullable. Normally, `field` will return the default
# value if the field isn't set. With this annotation, you get the value when
# the field is set and `null` when it isn't.
#
# Given
#
#     struct Test {
#         field @0 :Text $Dart.nullable;
#     }
#
# you get getters like so:
#
#     assert(structWith.field == "foo");
#     assert(structWithout.field == null);
#
# The setters are unchanged to match the Dart convention.
