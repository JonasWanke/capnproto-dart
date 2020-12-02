# main.capnp
@0x864fc76b3aa5d047;
struct ExampleStruct @0xf308e1fe3a31c244 {  # 48 bytes, 7 ptrs
  unit @0 :Void;  # bits[0, 0)
  boolean @1 :Bool;  # bits[0, 1)
  booleanList @2 :List(Bool);  # ptr[0]
  int8 @3 :Int8;  # bits[8, 16)
  int16 @4 :Int16;  # bits[16, 32)
  int32 @5 :Int32;  # bits[32, 64)
  int64 @6 :Int64;  # bits[64, 128)
  uint8 @7 :UInt8;  # bits[128, 136)
  uint16 @8 :UInt16;  # bits[144, 160)
  uint16List @9 :List(UInt16);  # ptr[1]
  uint32 @10 :UInt32;  # bits[160, 192)
  uint64 @11 :UInt64;  # bits[192, 256)
  float32 @12 :Float32;  # bits[256, 288)
  float32List @13 :List(Float32);  # ptr[2]
  float64 @14 :Float64;  # bits[320, 384)
  text @15 :Text;  # ptr[3]
  data @16 :Data;  # ptr[4]
  foo @17 :Foo;  # ptr[5]
  fooList @18 :List(Foo);  # ptr[6]
}
struct Foo @0xed08a768d3ca6b68 {  # 8 bytes, 0 ptrs
  bar @0 :UInt8;  # bits[0, 8)
}
const example @0xfe4b62167be78aec :ExampleStruct = (unit = void, boolean = true, booleanList = [true, false, false, true, true, true], int8 = -1, int16 = -1, int32 = -1, int64 = -1, uint8 = 1, uint16 = 1, uint16List = [1, 5], uint32 = 12345, uint64 = 1, float32 = 1, float32List = [1, 0.5, 2], float64 = 1, text = "Hello, world!", data = "\001\002\003\004\005", foo = (bar = 123), fooList = [(bar = 5), (bar = 6), (bar = 7)]);
