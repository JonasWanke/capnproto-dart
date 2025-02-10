// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';
import 'package:oxidized/oxidized.dart';

void main() {}

// Person

class Person_Reader {
  const Person_Reader(this.reader);

  static CapnpResult<Person_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Person_Reader.new);

  final StructReader reader;

  int get id => reader.getUint32(0, 0);

  bool get hasName => !reader.getPointerField(0).isNull;
  CapnpResult<TextReader> get name =>
      TextReader.fromPointer(reader.getPointerField(0), null);

  bool get hasEmail => !reader.getPointerField(1).isNull;
  CapnpResult<TextReader> get email =>
      TextReader.fromPointer(reader.getPointerField(1), null);

  bool get hasPhones => !reader.getPointerField(2).isNull;
  CapnpResult<StructListReader<Person_PhoneNumber_Reader>> get phones {
    return StructListReader.fromPointer(
      reader.getPointerField(2),
      Person_PhoneNumber_Reader.new,
      null,
    );
  }

  Person_Employment_Reader get employment => Person_Employment_Reader(reader);

  @override
  String toString() {
    return 'Person(id: $id, name: $name, email: $email, phones: $phones, '
        'employment: $employment)';
  }
}

// Person.PhoneNumber

class Person_PhoneNumber_Reader {
  const Person_PhoneNumber_Reader(this.reader);

  static CapnpResult<Person_PhoneNumber_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Person_PhoneNumber_Reader.new);

  final StructReader reader;

  bool get hasNumber => !reader.getPointerField(0).isNull;
  CapnpResult<TextReader> get number =>
      TextReader.fromPointer(reader.getPointerField(0), null);

  Result<Person_PhoneNumber_Type, NotInSchemaError> get type =>
      Person_PhoneNumber_Type.fromValue(reader.getUint16(0, 0));

  @override
  String toString() => 'Person_PhoneNumber(number: $number, type: $type)';
}

// Person.PhoneNumber.Type

enum Person_PhoneNumber_Type {
  mobile(0),
  home(1),
  work(2);

  const Person_PhoneNumber_Type(this.value);

  static Result<Person_PhoneNumber_Type, NotInSchemaError> fromValue(
    int value,
  ) {
    return switch (value) {
      0 => const Ok(Person_PhoneNumber_Type.mobile),
      1 => const Ok(Person_PhoneNumber_Type.home),
      2 => const Ok(Person_PhoneNumber_Type.work),
      _ => Err(NotInSchemaError(value)),
    };
  }

  final int value;
}

// Person.Employment

class Person_Employment_Reader {
  const Person_Employment_Reader(this.reader);

  final StructReader reader;

  bool get hasEmployer =>
      reader.getUint16(2, 0) == 1 && !reader.getPointerField(3).isNull;
  bool get hasSchool =>
      reader.getUint16(2, 0) == 2 && !reader.getPointerField(3).isNull;

  Result<Person_Employment_Which_Reader, NotInSchemaError> get which {
    return switch (reader.getUint16(2, 0)) {
      0 => const Ok(Person_Employment_Which_Unemployed()),
      1 => Ok(
          Person_Employment_Which_Employer(
            TextReader.fromPointer(reader.getPointerField(3), null),
          ),
        ),
      2 => Ok(
          Person_Employment_Which_School(
            TextReader.fromPointer(reader.getPointerField(3), null),
          ),
        ),
      3 => const Ok(Person_Employment_Which_SelfEmployed()),
      final variant => Err(NotInSchemaError(variant)),
    };
  }

  @override
  String toString() => which.toString();
}

typedef Person_Employment_Which_Reader
    = Person_Employment_Which<CapnpResult<TextReader>, CapnpResult<TextReader>>;

sealed class Person_Employment_Which<A0, A1> {
  const Person_Employment_Which();
}

final class Person_Employment_Which_Unemployed
    extends Person_Employment_Which<Never, Never> {
  const Person_Employment_Which_Unemployed();

  @override
  String toString() => 'Person_Employment_Which_Unemployed()';
}

final class Person_Employment_Which_Employer<A0>
    extends Person_Employment_Which<A0, Never> {
  const Person_Employment_Which_Employer(this.value);

  final A0 value;
}

final class Person_Employment_Which_School<A1>
    extends Person_Employment_Which<Never, A1> {
  const Person_Employment_Which_School(this.value);

  final A1 value;
}

final class Person_Employment_Which_SelfEmployed
    extends Person_Employment_Which<Never, Never> {
  const Person_Employment_Which_SelfEmployed();
}

// AddressBook

class AddressBook_Reader {
  const AddressBook_Reader(this.reader);

  static CapnpResult<AddressBook_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(AddressBook_Reader.new);

  final StructReader reader;

  bool get hasPeople => !reader.getPointerField(0).isNull;
  CapnpResult<StructListReader<Person_Reader>> get people {
    return StructListReader.fromPointer(
      reader.getPointerField(0),
      Person_Reader.new,
      null,
    );
  }
}

// import 'dart:io';
// import 'dart:typed_data';

// import 'package:capnproto/capnproto.dart';

// void main() {
//   // Read the compiled example message:
//   final compiledFile = File('example/message.bin');
//   print(compiledFile.absolute.path);
//   final data = compiledFile.readAsBytesSync();
//   final message = Message.fromBuffer(data.buffer);

//   // And decode it:
//   final testStruct = message.getRoot(TestStruct.new);
//   print(testStruct);
// }

// // For every struct in your Cap'n Proto definitions, create a class like this:
// class TestStruct extends Struct {
//   // Create a constructor like the following:
//   const TestStruct(super.reader);

//   // Write a getter for each member. They delegate to getters on `reader`,
//   // an accessor of the underlying buffer.
//   //
//   // The offsets are generated by Cap'n Proto if you execute the following
//   // command:
//   //
//   // > capnp compile -ocapnp main.capnp > main-compiled.capnp
//   //
//   // (Where `main.capnp` is your source file and `main-compiled.capnp` gets
//   // generated.)
//   //
//   // You then fill in the offsets for every getter as follows:
//   //
//   // * don't write a field for `Void`
//   // * bits for `Bool`
//   //   E.g., the generated line for the field `boolean` looks like:
//   //   boolean @1 :Bool;  # bits[0, 1)
//   //                             ^ You want this number.
//   // * bytes for other primitives (i.e., numbers)
//   //   E.g., the generated line for the field `int8` looks like:
//   //   int8 @3 :Int8;  # bits[8, 16)
//   //                          ^ You want this number, divided by eight (or
//   //                            `CapnpConstants.bitsPerByte`). `TODO`
//   //   Hence: ``
//   // * `dataSectionLengthInWords + <pointerIndex>` for nested structs and lists.
//   //   E.g., the generated line for the field `float32List` looks like:
//   //   float32List @13 :List(Float32);  # ptr[2]
//   //                                          ^ You want this number.
//   //   Hence: `reader.getFloat32List(dataSectionLengthInWords + 2)`
//   //
//   // For inner structs and lists of structs, you also have to pass in a
//   // `StructFactory`, which is used to actually instantiate those structs. This
//   // is why we wrote the static function `from` above.

//   bool get boolean => reader.getBool(0);
//   BoolList get booleanList => reader.getBoolList(0);
//   int get int8 => reader.getInt8(1);
//   int get int16 => reader.getInt16(1);
//   int get int32 => reader.getInt32(1);
//   int get int64 => reader.getInt64(1);
//   int get uint8 => reader.getUInt8(16);
//   int get uint16 => reader.getUInt16(9);
//   Uint16List get uint16List => reader.getUInt16List(1);
//   int get uint32 => reader.getUInt32(5);
//   int get uint64 => reader.getUInt64(3);
//   double get float32 => reader.getFloat32(8);
//   Float32List get float32List => reader.getFloat32List(2);
//   double get float64 => reader.getFloat64(5);
//   String get text => reader.getText(3);
//   Uint8List get data => reader.getData(4);
//   Foo get foo => reader.getStruct(5, Foo.new);
//   CompositeList<Foo> get fooList => reader.getCompositeList(6, Foo.new);

//   // This is optional:
//   @override
//   String toString() {
//     return 'TestStruct(unit: <void>, boolean: _boolean, '
// ignore: lines_longer_than_80_chars
//         'booleanList: _booleanList, int8: _int8, int16: _int16, int32: _int32, '
//         'int64: _int64, uint8: _uint8, uint16: _uint16, '
//         'uint16List: _uint16List, uint32: _uint32, uint64: _uint64, '
//         'float32: _float32, float32List: _float32List, float64: _float64, '
//         'text: _text, data: _data, foo: _foo, fooList: _fooList)';
//   }
// }

// class Foo extends Struct {
//   const Foo(super.reader);

//   int get bar => reader.getUInt8(0);

//   @override
//   String toString() => 'Foo(bar: _bar)';
// }
