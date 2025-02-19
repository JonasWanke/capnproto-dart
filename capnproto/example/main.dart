// ignore_for_file: avoid_print, unreachable_from_main, camel_case_types

import 'dart:io';

import 'package:capnproto/capnproto.dart';

Future<void> main(List<String> args) async {
  args = [
    '../../capnproto-rust/example/addressbook/data.capnp',
    '../output.capnp',
  ];
  final readFile = File(args[0]);
  final writeFile = File(args[1]);

  final bytes = await readFile.readAsBytes();
  final addressBook = readMessage(bytes.buffer.asByteData())
      .unwrap()
      .getRootAsStruct(AddressBook_Reader.new)
      .unwrap();
  print(addressBook);

  await _writeAddressBookTo(writeFile);
}

Future<void> _writeAddressBookTo(File file) async {
  final message = MessageBuilder();
  final addressBook = message.initRoot(AddressBook_Builder.fromPointer);
  final people = addressBook.initPeople(2);

  final alice = people[0];
  alice.id = 123;
  alice.name = 'Alice';
  alice.email = 'alice@example.com';
  final alicePhones = alice.initPhones(1);
  alicePhones[0].number = '555-1212';
  alicePhones[0].type = Person_PhoneNumber_Type.mobile;
  alice.employment.school = 'MIT';

  final bob = people[1];
  bob.id = 456;
  bob.name = 'Bob';
  bob.email = 'bob@example.com';
  final bobPhones = bob.initPhones(2);
  bobPhones[0].number = '555-4567';
  bobPhones[0].type = Person_PhoneNumber_Type.home;
  bobPhones[1].number = '555-7654';
  bobPhones[1].type = Person_PhoneNumber_Type.work;
  bob.employment.setUnemployed();

  final sink = file.openWrite();
  writeMessage(message, sink);
  await sink.close();
}

// Person

class Person_Reader extends CapnpStructReader {
  const Person_Reader(super.reader);

  int get id => reader.getUInt32(0, 0);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  bool get hasEmail => !reader.getPointer(1).isNull;
  String get email => reader.getPointer(1).getText(null).unwrap();

  bool get hasPhones => !reader.getPointer(2).isNull;
  StructListReader<Person_PhoneNumber_Reader> get phones {
    return StructListReader.fromPointer(
      reader.getPointer(2),
      Person_PhoneNumber_Reader.new,
      null,
    ).unwrap();
  }

  Person_Employment_Reader get employment => Person_Employment_Reader(reader);

  @override
  String toString() {
    return '(id = $id, name = $name, email = $email, phones = $phones, '
        'employment = $employment)';
  }
}

class Person_Builder extends CapnpStructBuilder<Person_Reader> {
  const Person_Builder(super.builder);

  static const structSize = StructSize(dataWords: 1, pointerCount: 4);

  static final fromPointer = FromPointerBuilder(
    initPointer: (builder, length) =>
        Person_Builder(builder.initStruct(structSize)),
    getFromPointer: (builder, defaultValue) =>
        builder.getStruct(structSize, defaultValue).map(Person_Builder.new),
  );

  @override
  Person_Reader get asReader => Person_Reader(builder.asReader);

  int get id => builder.getUInt32(0, 0);
  set id(int value) => builder.setUInt32(0, value, 0);

  bool get hasName => !builder.getPointer(0).isNull;
  String get name => builder.getPointer(0).getText(null).unwrap();
  set name(String value) => builder.getPointer(0).setText(value);

  bool get hasEmail => !builder.getPointer(1).isNull;
  String get email => builder.getPointer(1).getText(null).unwrap();
  set email(String value) => builder.getPointer(1).setText(value);

  StructListBuilder<Person_PhoneNumber_Builder, Person_PhoneNumber_Reader>
      get phones {
    return StructListBuilder.getFromPointer(
      builder.getPointer(2),
      Person_PhoneNumber_Builder.structSize,
      Person_PhoneNumber_Builder.new,
      Person_PhoneNumber_Reader.new,
      null,
    ).unwrap();
  }

  StructListBuilder<Person_PhoneNumber_Builder, Person_PhoneNumber_Reader>
      initPhones(int length) {
    return StructListBuilder.initPointer(
      builder.getPointer(2),
      length,
      Person_PhoneNumber_Builder.structSize,
      Person_PhoneNumber_Builder.new,
      Person_PhoneNumber_Reader.new,
    );
  }

  Person_Employment_Builder get employment =>
      Person_Employment_Builder(builder);
}

// Person.PhoneNumber

class Person_PhoneNumber_Reader extends CapnpStructReader {
  const Person_PhoneNumber_Reader(super.reader);

  bool get hasNumber => !reader.getPointer(0).isNull;
  String get number => reader.getPointer(0).getText(null).unwrap();

  Person_PhoneNumber_Type get type =>
      Person_PhoneNumber_Type.fromValue(reader.getUInt16(0, 0));

  @override
  String toString() => '(number = $number, type = $type)';
}

class Person_PhoneNumber_Builder
    extends CapnpStructBuilder<Person_PhoneNumber_Reader> {
  const Person_PhoneNumber_Builder(super.builder);

  static const structSize = StructSize(dataWords: 1, pointerCount: 1);

  static final fromPointer = FromPointerBuilder(
    initPointer: (builder, length) =>
        Person_PhoneNumber_Builder(builder.initStruct(structSize)),
    getFromPointer: (builder, defaultValue) => builder
        .getStruct(structSize, defaultValue)
        .map(Person_PhoneNumber_Builder.new),
  );

  @override
  Person_PhoneNumber_Reader get asReader =>
      Person_PhoneNumber_Reader(builder.asReader);

  bool get hasNumber => !builder.getPointer(0).isNull;
  String get number => builder.getPointer(0).getText(null).unwrap();
  set number(String value) => builder.getPointer(0).setText(value);

  Person_PhoneNumber_Type get type =>
      Person_PhoneNumber_Type.fromValue(builder.getUInt16(0, 0));
  set type(Person_PhoneNumber_Type value) {
    assert(value != Person_PhoneNumber_Type.notInSchema);
    builder.setUInt16(0, value.value!, 0);
  }
}

// Person.PhoneNumber.Type

enum Person_PhoneNumber_Type {
  mobile(0),
  home(1),
  work(2),
  notInSchema(null);

  const Person_PhoneNumber_Type(this.value);

  factory Person_PhoneNumber_Type.fromValue(int value) {
    return switch (value) {
      0 => Person_PhoneNumber_Type.mobile,
      1 => Person_PhoneNumber_Type.home,
      2 => Person_PhoneNumber_Type.work,
      _ => Person_PhoneNumber_Type.notInSchema,
    };
  }

  final int? value;
}

// Person.Employment

class Person_Employment_Reader extends CapnpStructReader {
  const Person_Employment_Reader(super.reader);

  bool get hasEmployer =>
      reader.getUInt16(2, 0) == 1 && !reader.getPointer(3).isNull;
  bool get hasSchool =>
      reader.getUInt16(2, 0) == 2 && !reader.getPointer(3).isNull;

  Person_Employment_union_Reader get which {
    return switch (reader.getUInt16(2, 0)) {
      0 => Person_Employment_unemployed_Reader(reader),
      1 => Person_Employment_employer_Reader(reader),
      2 => Person_Employment_school_Reader(reader),
      3 => Person_Employment_selfEmployed_Reader(reader),
      _ => Person_Employment_notInSchema_Reader(reader),
    };
  }

  @override
  String toString() => which.toString();
}

class Person_Employment_Builder
    extends CapnpStructBuilder<Person_Employment_Reader> {
  const Person_Employment_Builder(super.builder);

  static const structSize = StructSize(dataWords: 1, pointerCount: 4);

  static final fromPointer = FromPointerBuilder(
    initPointer: (builder, length) =>
        Person_Employment_Builder(builder.initStruct(structSize)),
    getFromPointer: (builder, defaultValue) => builder
        .getStruct(structSize, defaultValue)
        .map(Person_Employment_Builder.new),
  );

  @override
  Person_Employment_Reader get asReader =>
      Person_Employment_Reader(builder.asReader);

  void setUnemployed() => builder.setUInt16(2, 0, 0);

  // `initFoo(int length)` for lists/data and `initFoo()` for structs
  // ignore: avoid_setters_without_getters
  set employer(String value) {
    builder.setUInt16(2, 1, 0);
    builder.getPointer(3).setText(value);
  }

  // ignore: avoid_setters_without_getters
  set school(String value) {
    builder.setUInt16(2, 2, 0);
    builder.getPointer(3).setText(value);
  }

  void setSelfEmployed() => builder.setUInt16(2, 3, 0);

  // TODO(JonasWanke): figure out `which` getter with strings
}

sealed class Person_Employment_union_Reader extends CapnpStructReader {
  const Person_Employment_union_Reader(super.reader);
}

class Person_Employment_unemployed_Reader
    extends Person_Employment_union_Reader {
  const Person_Employment_unemployed_Reader(super.reader);

  @override
  String toString() => '(unemployed = void)';
}

class Person_Employment_employer_Reader extends Person_Employment_union_Reader {
  const Person_Employment_employer_Reader(super.reader);

  String get value => reader.getPointer(3).getText(null).unwrap();

  @override
  String toString() => '(employer = $value)';
}

class Person_Employment_school_Reader extends Person_Employment_union_Reader {
  const Person_Employment_school_Reader(super.reader);

  String get value => reader.getPointer(3).getText(null).unwrap();

  @override
  String toString() => '(school = $value)';
}

class Person_Employment_selfEmployed_Reader
    extends Person_Employment_union_Reader {
  const Person_Employment_selfEmployed_Reader(super.reader);

  @override
  String toString() => '(selfEmployed = void)';
}

class Person_Employment_notInSchema_Reader
    extends Person_Employment_union_Reader {
  const Person_Employment_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// AddressBook

class AddressBook_Reader extends CapnpStructReader {
  const AddressBook_Reader(super.reader);

  bool get hasPeople => !reader.getPointer(0).isNull;
  StructListReader<Person_Reader> get people {
    return StructListReader.fromPointer(
      reader.getPointer(0),
      Person_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() => '(people = $people)';
}

class AddressBook_Builder extends CapnpStructBuilder<AddressBook_Reader> {
  const AddressBook_Builder(super.builder);

  static const structSize = StructSize(dataWords: 0, pointerCount: 1);

  static final fromPointer = FromPointerBuilder(
    initPointer: (builder, length) =>
        AddressBook_Builder(builder.initStruct(structSize)),
    getFromPointer: (builder, defaultValue) => builder
        .getStruct(structSize, defaultValue)
        .map(AddressBook_Builder.new),
  );

  @override
  AddressBook_Reader get asReader => AddressBook_Reader(builder.asReader);

  bool get hasPeople => !builder.getPointer(0).isNull;
  StructListBuilder<Person_Builder, Person_Reader> get people {
    return StructListBuilder.getFromPointer(
      builder.getPointer(0),
      Person_Builder.structSize,
      Person_Builder.new,
      Person_Reader.new,
      null,
    ).unwrap();
  }

  StructListBuilder<Person_Builder, Person_Reader> initPeople(int length) {
    return StructListBuilder.initPointer(
      builder.getPointer(0),
      length,
      Person_Builder.structSize,
      Person_Builder.new,
      Person_Reader.new,
    );
  }

  @override
  String toString() => '(people = $people)';
}
