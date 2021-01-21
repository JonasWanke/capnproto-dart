@0x864fc76b3aa5d047;

struct ExampleStruct {
  unit @0 :Void;
  boolean @1 :Bool;
  booleanList @2 :List(Bool);
  int8 @3 :Int8;
  int16 @4 :Int16;
  int32 @5 :Int32;
  int64 @6 :Int64;
  uint8 @7 :UInt8;
  uint16 @8 :UInt16;
  uint16List @9 :List(UInt16);
  uint32 @10 :UInt32;
  uint64 @11 :UInt64;
  float32 @12 :Float32;
  float32List @13 :List(Float32);
  float64 @14 :Float64;
  text @15 :Text;
  data @16 :Data;
  foo @17 :Foo;
  fooList @18 :List(Foo);
}

struct Foo {
  bar @0 :UInt8;
}

const example :ExampleStruct = (
  boolean = true,
  booleanList = [true, false, false, true, true, true],
  int8 = -1,
  int16 = -1,
  int32 = -1,
  int64 = -1,
  uint8 = 1,
  uint16 = 1,
  uint16List = [1, 5],
  uint32 = 12345,
  uint64 = 1,
  float32 = 1,
  float32List = [1, 0.5, 2],
  float64 = 1,
  text = "Hello, world!",
  data = 0x"01 02 03 04 05",
  foo = (bar = 123),
  fooList = [(bar = 5), (bar = 6), (bar = 7)],
);
