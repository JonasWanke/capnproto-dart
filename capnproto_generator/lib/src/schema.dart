// ignore_for_file: camel_case_types

import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';

// Node

final class Node_Reader extends CapnpStructReader {
  const Node_Reader(super.reader);

  static CapnpResult<Node_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Node_Reader.new);

  int get id => reader.getUInt64(0, 0);

  bool get hasDisplayName => !reader.getPointer(0).isNull;
  String get displayName => reader.getPointer(0).getText(null).unwrap();

  int get displayNamePrefixLength => reader.getUInt32(2, 0);

  int get scopeId => reader.getUInt64(2, 0);

  bool get hasParameters => !reader.getPointer(5).isNull;
  StructListReader<Node_Parameter_Reader> get parameters {
    return StructListReader.fromPointer(
      reader.getPointer(5),
      Node_Parameter_Reader.new,
      null,
    ).unwrap();
  }

  bool get isGeneric => reader.getBool(288, false);

  bool get hasNestedNodes => !reader.getPointer(1).isNull;
  StructListReader<Node_NestedNode_Reader> get nestedNodes {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      Node_NestedNode_Reader.new,
      null,
    ).unwrap();
  }

  bool get hasAnnotations => !reader.getPointer(2).isNull;
  StructListReader<Annotation_Reader> get annotations {
    return StructListReader.fromPointer(
      reader.getPointer(2),
      Annotation_Reader.new,
      null,
    ).unwrap();
  }

  Node_Which_Reader get which {
    return switch (reader.getUInt16(6, 0)) {
      0 => Node_Which_File_Reader(reader),
      1 => Node_Which_Struct_Reader(reader),
      2 => Node_Which_Enum_Reader(reader),
      3 => Node_Which_Interface_Reader(reader),
      4 => Node_Which_Const_Reader(reader),
      5 => Node_Which_Annotation_Reader(reader),
      _ => Node_Which_NotInSchema_Reader(reader),
    };
  }

  @override
  String toString() {
    return '(id = $id, displayName = $displayName, '
        'displayNamePrefixLength = $displayNamePrefixLength, '
        'scopeId = $scopeId, isGeneric = $isGeneric)';
  }
}

sealed class Node_Which_Reader extends CapnpStructReader {
  const Node_Which_Reader(super.reader);
}

final class Node_Which_File_Reader extends Node_Which_Reader {
  const Node_Which_File_Reader(super.reader);

  @override
  String toString() => '(file = ())';
}

final class Node_Which_Struct_Reader extends Node_Which_Reader {
  const Node_Which_Struct_Reader(super.reader);

  int get dataWordCount => reader.getUInt16(7, 0);

  int get pointerCount => reader.getUInt16(12, 0);

  ElementSize get preferredListEncoding =>
      ElementSize.fromValue(reader.getUInt16(13, 0));

  bool get isGroup => reader.getBool(226, false);

  int get discriminantCount => reader.getUInt16(15, 0);

  int get discriminantOffset => reader.getUInt16(8, 0);

  bool get hasFields => !reader.getPointer(3).isNull;
  StructListReader<Field_Reader> get fields {
    return StructListReader.fromPointer(
      reader.getPointer(3),
      Field_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() {
    return '(struct = (dataWordCount = $dataWordCount, '
        'preferredListEncoding = $preferredListEncoding, '
        'pointerCount = $pointerCount, isGroup = $isGroup, '
        'discriminantCount = $discriminantCount, '
        'discriminantOffset = $discriminantOffset, '
        'fields = [${fields.join(', ')}])';
  }
}

final class Node_Which_Enum_Reader extends Node_Which_Reader {
  const Node_Which_Enum_Reader(super.reader);

  bool get hasEnumerants => !reader.getPointer(3).isNull;
  StructListReader<Enumerant_Reader> get enumerants {
    return StructListReader.fromPointer(
      reader.getPointer(3),
      Enumerant_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() => '(enum = (enumerants = [${enumerants.join(', ')}]))';
}

final class Node_Which_Interface_Reader extends Node_Which_Reader {
  const Node_Which_Interface_Reader(super.reader);

  // TODO(JonasWanke): methods, superclasses

  @override
  String toString() => '(interface = ())';
}

final class Node_Which_Const_Reader extends Node_Which_Reader {
  const Node_Which_Const_Reader(super.reader);

  bool get hasType => !reader.getPointer(3).isNull;
  Type_Reader get type =>
      Type_Reader(reader.getPointer(3).getStruct(null).unwrap());

  Value_Reader get value =>
      Value_Reader(reader.getPointer(4).getStruct(null).unwrap());

  @override
  String toString() => '(const = (type = $type, value = $value))';
}

final class Node_Which_Annotation_Reader extends Node_Which_Reader {
  const Node_Which_Annotation_Reader(super.reader);

  bool get hasType => !reader.getPointer(3).isNull;
  Type_Reader get type =>
      Type_Reader(reader.getPointer(3).getStruct(null).unwrap());

  bool get targetsFile => reader.getBool(112, false);

  bool get targetsConst => reader.getBool(113, false);

  bool get targetsEnum => reader.getBool(114, false);

  bool get targetsEnumerant => reader.getBool(115, false);

  bool get targetsStruct => reader.getBool(116, false);

  bool get targetsField => reader.getBool(117, false);

  bool get targetsUnion => reader.getBool(118, false);

  bool get targetsGroup => reader.getBool(119, false);

  bool get targetsInterface => reader.getBool(120, false);

  bool get targetsMethod => reader.getBool(121, false);

  bool get targetsParam => reader.getBool(122, false);

  bool get targetsAnnotation => reader.getBool(123, false);

  @override
  String toString() {
    return '(annotation = (type = $type, targetsFile = $targetsFile, '
        'targetsConst = $targetsConst, targetsEnum = $targetsEnum, '
        'targetsEnumerant = $targetsEnumerant, targetsStruct = $targetsStruct, '
        'targetsField = $targetsField, targetsUnion = $targetsUnion, '
        'targetsGroup = $targetsGroup, targetsInterface = $targetsInterface, '
        'targetsMethod = $targetsMethod, targetsParam = $targetsParam, '
        'targetsAnnotation = $targetsAnnotation))';
  }
}

final class Node_Which_NotInSchema_Reader extends Node_Which_Reader {
  const Node_Which_NotInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Node.Parameter

final class Node_Parameter_Reader extends CapnpStructReader {
  const Node_Parameter_Reader(super.reader);

  static CapnpResult<Node_Parameter_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Node_Parameter_Reader.new);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  @override
  String toString() => '(name = $name)';
}

final class Node_NestedNode_Reader extends CapnpStructReader {
  const Node_NestedNode_Reader(super.reader);

  static CapnpResult<Node_NestedNode_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Node_NestedNode_Reader.new);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  int get id => reader.getUInt64(0, 0);

  @override
  String toString() => '(name = $name, id = $id)';
}

// Node.SourceInfo

final class Node_SourceInfo_Reader extends CapnpStructReader {
  const Node_SourceInfo_Reader(super.reader);

  static CapnpResult<Node_SourceInfo_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Node_SourceInfo_Reader.new);

  int get id => reader.getUInt64(0, 0);

  bool get hasDocComment => !reader.getPointer(0).isNull;
  String get docComment => reader.getPointer(0).getText(null).unwrap();

  bool get hasMembers => !reader.getPointer(1).isNull;
  StructListReader<Node_SourceInfo_Member_Reader> get members {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      Node_SourceInfo_Member_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() =>
      '(id = $id, docComment = $docComment, members = [${members.join(', ')}])';
}

// Node.SourceInfo.Member

final class Node_SourceInfo_Member_Reader extends CapnpStructReader {
  const Node_SourceInfo_Member_Reader(super.reader);

  static CapnpResult<Node_SourceInfo_Member_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Node_SourceInfo_Member_Reader.new);

  bool get hasDocComment => !reader.getPointer(0).isNull;
  String get docComment => reader.getPointer(0).getText(null).unwrap();

  @override
  String toString() => '(docComment = $docComment)';
}

// Field

final class Field_Reader extends CapnpStructReader {
  const Field_Reader(super.reader);

  static CapnpResult<Field_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Field_Reader.new);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  int get codeOrder => reader.getUInt16(0, 0);

  bool get hasAnnotations => !reader.getPointer(1).isNull;
  StructListReader<Annotation_Reader> get annotations {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      Annotation_Reader.new,
      null,
    ).unwrap();
  }

  int get discriminantValue => reader.getUInt16(1, 65535);

  Field_Which_Reader get which {
    return switch (reader.getUInt16(4, 0)) {
      0 => Field_Which_Slot_Reader(reader),
      1 => Field_Which_Group_Reader(reader),
      _ => Field_Which_NotInSchema_Reader(reader),
    };
  }

  Field_Ordinal_Which_Reader get ordinal {
    return switch (reader.getUInt16(5, 0)) {
      0 => Field_Ordinal_Which_Implicit_Reader(reader),
      1 => Field_Ordinal_Which_Explicit_Reader(reader),
      _ => Field_Ordinal_Which_NotInSchema_Reader(reader),
    };
  }

  static const noDiscriminant = 65535;

  @override
  String toString() {
    return '(name = $name, codeOrder = $codeOrder, '
        'discriminantValue = $discriminantValue, which = $which, '
        'ordinal = $ordinal)';
  }
}

sealed class Field_Which_Reader extends CapnpStructReader {
  const Field_Which_Reader(super.reader);
}

final class Field_Which_Slot_Reader extends Field_Which_Reader {
  const Field_Which_Slot_Reader(super.reader);

  int get offset => reader.getUInt32(1, 0);

  bool get hasType => !reader.getPointer(2).isNull;
  Type_Reader get type =>
      Type_Reader(reader.getPointer(2).getStruct(null).unwrap());

  Value_Reader get defaultValue =>
      Value_Reader(reader.getPointer(3).getStruct(null).unwrap());

  bool get hadExplicitDefault => reader.getBool(128, false);

  @override
  String toString() {
    return '(slot = (offset = $offset, type = $type, '
        'hadExplicitDefault = $hadExplicitDefault, '
        'defaultValue = $defaultValue))';
  }
}

final class Field_Which_Group_Reader extends Field_Which_Reader {
  const Field_Which_Group_Reader(super.reader);

  int get typeId => reader.getUInt64(2, 0);

  @override
  String toString() => '(group = (typeId = $typeId))';
}

final class Field_Which_NotInSchema_Reader extends Field_Which_Reader {
  const Field_Which_NotInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

sealed class Field_Ordinal_Which_Reader extends CapnpStructReader {
  const Field_Ordinal_Which_Reader(super.reader);
}

final class Field_Ordinal_Which_Implicit_Reader
    extends Field_Ordinal_Which_Reader {
  const Field_Ordinal_Which_Implicit_Reader(super.reader);

  @override
  String toString() => '(implicit = ())';
}

final class Field_Ordinal_Which_Explicit_Reader
    extends Field_Ordinal_Which_Reader {
  const Field_Ordinal_Which_Explicit_Reader(super.reader);

  int get value => reader.getUInt16(6, 0);

  @override
  String toString() => '(explicit = $value)';
}

final class Field_Ordinal_Which_NotInSchema_Reader
    extends Field_Ordinal_Which_Reader {
  const Field_Ordinal_Which_NotInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Node.SourceInfo.Member

final class Enumerant_Reader extends CapnpStructReader {
  const Enumerant_Reader(super.reader);

  static CapnpResult<Enumerant_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Enumerant_Reader.new);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  int get codeOrder => reader.getUInt16(0, 0);

  bool get hasAnnotations => !reader.getPointer(1).isNull;
  StructListReader<Annotation_Reader> get annotations {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      Annotation_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() {
    return '(name = $name, codeOrder = $codeOrder, '
        'annotations = [${annotations.join(', ')}])';
  }
}

// Type

final class Type_Reader extends CapnpStructReader {
  const Type_Reader(super.reader);

  static CapnpResult<Type_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Type_Reader.new);

  Type_Which_Reader get which {
    return switch (reader.getUInt16(0, 0)) {
      0 => Type_Which_Void_Reader(reader),
      1 => Type_Which_Bool_Reader(reader),
      2 => Type_Which_Int8_Reader(reader),
      3 => Type_Which_Int16_Reader(reader),
      4 => Type_Which_Int32_Reader(reader),
      5 => Type_Which_Int64_Reader(reader),
      6 => Type_Which_Uint8_Reader(reader),
      7 => Type_Which_Uint16_Reader(reader),
      8 => Type_Which_Uint32_Reader(reader),
      9 => Type_Which_Uint64_Reader(reader),
      10 => Type_Which_Float32_Reader(reader),
      11 => Type_Which_Float64_Reader(reader),
      12 => Type_Which_Text_Reader(reader),
      13 => Type_Which_Data_Reader(reader),
      14 => Type_Which_List_Reader(reader),
      15 => Type_Which_Enum_Reader(reader),
      16 => Type_Which_Struct_Reader(reader),
      17 => Type_Which_Interface_Reader(reader),
      18 => Type_Which_AnyPointer_Reader(reader),
      _ => Type_Which_NotInSchema_Reader(reader),
    };
  }

  @override
  String toString() => '($which)';
}

sealed class Type_Which_Reader extends CapnpStructReader {
  const Type_Which_Reader(super.reader);
}

final class Type_Which_Void_Reader extends Type_Which_Reader {
  const Type_Which_Void_Reader(super.reader);

  @override
  String toString() => '(void = ())';
}

final class Type_Which_Bool_Reader extends Type_Which_Reader {
  const Type_Which_Bool_Reader(super.reader);

  @override
  String toString() => '(bool = ())';
}

final class Type_Which_Int8_Reader extends Type_Which_Reader {
  const Type_Which_Int8_Reader(super.reader);

  @override
  String toString() => '(int8 = ())';
}

final class Type_Which_Int16_Reader extends Type_Which_Reader {
  const Type_Which_Int16_Reader(super.reader);

  @override
  String toString() => '(int16 = ())';
}

final class Type_Which_Int32_Reader extends Type_Which_Reader {
  const Type_Which_Int32_Reader(super.reader);

  @override
  String toString() => '(int32 = ())';
}

final class Type_Which_Int64_Reader extends Type_Which_Reader {
  const Type_Which_Int64_Reader(super.reader);

  @override
  String toString() => '(int64 = ())';
}

final class Type_Which_Uint8_Reader extends Type_Which_Reader {
  const Type_Which_Uint8_Reader(super.reader);

  @override
  String toString() => '(uint8 = ())';
}

final class Type_Which_Uint16_Reader extends Type_Which_Reader {
  const Type_Which_Uint16_Reader(super.reader);

  @override
  String toString() => '(uint16 = ())';
}

final class Type_Which_Uint32_Reader extends Type_Which_Reader {
  const Type_Which_Uint32_Reader(super.reader);

  @override
  String toString() => '(uint32 = ())';
}

final class Type_Which_Uint64_Reader extends Type_Which_Reader {
  const Type_Which_Uint64_Reader(super.reader);

  @override
  String toString() => '(uint64 = ())';
}

final class Type_Which_Float32_Reader extends Type_Which_Reader {
  const Type_Which_Float32_Reader(super.reader);

  @override
  String toString() => '(float32 = ())';
}

final class Type_Which_Float64_Reader extends Type_Which_Reader {
  const Type_Which_Float64_Reader(super.reader);

  @override
  String toString() => '(float64 = ())';
}

final class Type_Which_Text_Reader extends Type_Which_Reader {
  const Type_Which_Text_Reader(super.reader);

  @override
  String toString() => '(text = ())';
}

final class Type_Which_Data_Reader extends Type_Which_Reader {
  const Type_Which_Data_Reader(super.reader);

  @override
  String toString() => '(data = ())';
}

final class Type_Which_List_Reader extends Type_Which_Reader {
  const Type_Which_List_Reader(super.reader);

  bool get hasElementType => !reader.getPointer(0).isNull;
  Type_Reader get elementType =>
      Type_Reader(reader.getPointer(0).getStruct(null).unwrap());

  @override
  String toString() => '(list = (elementType = $elementType))';
}

final class Type_Which_Enum_Reader extends Type_Which_Reader {
  const Type_Which_Enum_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(enum = (typeId = $typeId))';
}

final class Type_Which_Struct_Reader extends Type_Which_Reader {
  const Type_Which_Struct_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(struct = (typeId = $typeId))';
}

final class Type_Which_Interface_Reader extends Type_Which_Reader {
  const Type_Which_Interface_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(interface = (typeId = $typeId))';
}

final class Type_Which_AnyPointer_Reader extends Type_Which_Reader {
  const Type_Which_AnyPointer_Reader(super.reader);

  // TODO(JonasWanke): union

  @override
  String toString() => '(anyPointer = ())';
}

final class Type_Which_NotInSchema_Reader extends Type_Which_Reader {
  const Type_Which_NotInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Value

final class Value_Reader extends CapnpStructReader {
  const Value_Reader(super.reader);

  static CapnpResult<Value_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Value_Reader.new);

  Value_Which_Reader get which {
    return switch (reader.getUInt16(0, 0)) {
      0 => Value_Which_Void_Reader(reader),
      1 => Value_Which_Bool_Reader(reader),
      2 => Value_Which_Int8_Reader(reader),
      3 => Value_Which_Int16_Reader(reader),
      4 => Value_Which_Int32_Reader(reader),
      5 => Value_Which_Int64_Reader(reader),
      6 => Value_Which_Uint8_Reader(reader),
      7 => Value_Which_Uint16_Reader(reader),
      8 => Value_Which_Uint32_Reader(reader),
      9 => Value_Which_Uint64_Reader(reader),
      10 => Value_Which_Float32_Reader(reader),
      11 => Value_Which_Float64_Reader(reader),
      12 => Value_Which_Text_Reader(reader),
      13 => Value_Which_Data_Reader(reader),
      14 => Value_Which_List_Reader(reader),
      15 => Value_Which_Enum_Reader(reader),
      16 => Value_Which_Struct_Reader(reader),
      17 => Value_Which_Interface_Reader(reader),
      18 => Value_Which_AnyPointer_Reader(reader),
      _ => Value_Which_NotInSchema_Reader(reader),
    };
  }

  @override
  String toString() => '($which)';
}

sealed class Value_Which_Reader extends CapnpStructReader {
  const Value_Which_Reader(super.reader);
}

final class Value_Which_Void_Reader extends Value_Which_Reader {
  const Value_Which_Void_Reader(super.reader);

  void get value {}

  @override
  String toString() => 'void = ()';
}

final class Value_Which_Bool_Reader extends Value_Which_Reader {
  const Value_Which_Bool_Reader(super.reader);

  bool get value => reader.getBool(16, false);

  @override
  String toString() => 'bool = $value';
}

final class Value_Which_Int8_Reader extends Value_Which_Reader {
  const Value_Which_Int8_Reader(super.reader);

  int get value => reader.getInt8(2, 0);

  @override
  String toString() => 'int8 = $value';
}

final class Value_Which_Int16_Reader extends Value_Which_Reader {
  const Value_Which_Int16_Reader(super.reader);

  int get value => reader.getInt16(1, 0);

  @override
  String toString() => 'int16 = $value';
}

final class Value_Which_Int32_Reader extends Value_Which_Reader {
  const Value_Which_Int32_Reader(super.reader);

  int get value => reader.getInt32(1, 0);

  @override
  String toString() => 'int32 = $value';
}

final class Value_Which_Int64_Reader extends Value_Which_Reader {
  const Value_Which_Int64_Reader(super.reader);

  int get value => reader.getInt64(1, 0);

  @override
  String toString() => 'int64 = $value';
}

final class Value_Which_Uint8_Reader extends Value_Which_Reader {
  const Value_Which_Uint8_Reader(super.reader);

  int get value => reader.getUInt8(2, 0);

  @override
  String toString() => 'uint8 = $value';
}

final class Value_Which_Uint16_Reader extends Value_Which_Reader {
  const Value_Which_Uint16_Reader(super.reader);

  int get value => reader.getUInt16(1, 0);

  @override
  String toString() => 'uint16 = $value';
}

final class Value_Which_Uint32_Reader extends Value_Which_Reader {
  const Value_Which_Uint32_Reader(super.reader);

  int get value => reader.getUInt32(1, 0);

  @override
  String toString() => 'uint32 = $value';
}

final class Value_Which_Uint64_Reader extends Value_Which_Reader {
  const Value_Which_Uint64_Reader(super.reader);

  int get value => reader.getUInt64(1, 0);

  @override
  String toString() => 'uint64 = $value';
}

final class Value_Which_Float32_Reader extends Value_Which_Reader {
  const Value_Which_Float32_Reader(super.reader);

  double get value => reader.getFloat32(1, 0);

  @override
  String toString() => 'float32 = $value';
}

final class Value_Which_Float64_Reader extends Value_Which_Reader {
  const Value_Which_Float64_Reader(super.reader);

  double get value => reader.getFloat64(1, 0);

  @override
  String toString() => 'float64 = $value';
}

final class Value_Which_Text_Reader extends Value_Which_Reader {
  const Value_Which_Text_Reader(super.reader);

  String get value => reader.getPointer(0).getText(null).unwrap();

  @override
  String toString() => 'text = $value';
}

final class Value_Which_Data_Reader extends Value_Which_Reader {
  const Value_Which_Data_Reader(super.reader);

  ByteData get value => reader.getPointer(0).getData(null).unwrap();

  @override
  String toString() => 'data = $value';
}

final class Value_Which_List_Reader extends Value_Which_Reader {
  const Value_Which_List_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'list = $value';
}

final class Value_Which_Enum_Reader extends Value_Which_Reader {
  const Value_Which_Enum_Reader(super.reader);

  int get value => reader.getUInt16(1, 0);

  @override
  String toString() => 'enum = $value';
}

final class Value_Which_Struct_Reader extends Value_Which_Reader {
  const Value_Which_Struct_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'struct = $value';
}

final class Value_Which_Interface_Reader extends Value_Which_Reader {
  const Value_Which_Interface_Reader(super.reader);

  @override
  String toString() => 'interface = ()';
}

final class Value_Which_AnyPointer_Reader extends Value_Which_Reader {
  const Value_Which_AnyPointer_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'anyPointer = $value';
}

final class Value_Which_NotInSchema_Reader extends Value_Which_Reader {
  const Value_Which_NotInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Annotation

final class Annotation_Reader extends CapnpStructReader {
  const Annotation_Reader(super.reader);

  static CapnpResult<Annotation_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Annotation_Reader.new);

  int get id => reader.getUInt64(0, 0);

  // TODO(JonasWanke): brand

  Value_Reader get value =>
      Value_Reader(reader.getPointer(0).getStruct(null).unwrap());

  @override
  String toString() => '(id = $id, value = $value)';
}

// ElementSize

enum ElementSize {
  empty(0),
  bit(1),
  byte(2),
  twoBytes(3),
  fourBytes(4),
  eightBytes(5),
  pointer(6),
  inlineComposite(7),
  notInSchema(null);

  const ElementSize(this.value);

  factory ElementSize.fromValue(int value) {
    return switch (value) {
      0 => ElementSize.empty,
      1 => ElementSize.bit,
      2 => ElementSize.byte,
      3 => ElementSize.twoBytes,
      4 => ElementSize.fourBytes,
      5 => ElementSize.eightBytes,
      6 => ElementSize.pointer,
      7 => ElementSize.inlineComposite,
      _ => ElementSize.notInSchema,
    };
  }

  final int? value;
}

// CapnpVersion

final class CapnpVersion_Reader extends CapnpStructReader {
  const CapnpVersion_Reader(super.reader);

  static CapnpResult<CapnpVersion_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(CapnpVersion_Reader.new);

  int get major => reader.getUInt16(0, 0);

  int get minor => reader.getUInt8(2, 0);

  int get micro => reader.getUInt8(3, 0);

  @override
  String toString() => '(major = $major, minor = $minor, micro = $micro)';
}

// CodeGeneratorRequest

final class CodeGeneratorRequest_Reader extends CapnpStructReader {
  const CodeGeneratorRequest_Reader(super.reader);

  static CapnpResult<CodeGeneratorRequest_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(CodeGeneratorRequest_Reader.new);

  bool get hasCapnpVersion => !reader.getPointer(2).isNull;
  CapnpVersion_Reader get capnpVersion =>
      CapnpVersion_Reader(reader.getPointer(2).getStruct(null).unwrap());

  bool get hasNodes => !reader.getPointer(0).isNull;
  StructListReader<Node_Reader> get nodes {
    return StructListReader.fromPointer(
      reader.getPointer(0),
      Node_Reader.new,
      null,
    ).unwrap();
  }

  bool get hasSourceInfo => !reader.getPointer(3).isNull;
  StructListReader<Node_SourceInfo_Reader> get sourceInfo {
    return StructListReader.fromPointer(
      reader.getPointer(3),
      Node_SourceInfo_Reader.new,
      null,
    ).unwrap();
  }

  bool get hasRequestedFiles => !reader.getPointer(1).isNull;
  StructListReader<CodeGeneratorRequest_RequestedFile_Reader>
      get requestedFiles {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      CodeGeneratorRequest_RequestedFile_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() {
    return '(capnpVersion = $capnpVersion, nodes = [${nodes.join(',\n')}], '
        'sourceInfo = [${sourceInfo.join(',\n')}], '
        'requestedFiles = [${requestedFiles.join(',\n')}])';
  }
}

// CodeGeneratorRequest.RequestedFile

final class CodeGeneratorRequest_RequestedFile_Reader
    extends CapnpStructReader {
  const CodeGeneratorRequest_RequestedFile_Reader(super.reader);

  static CapnpResult<CodeGeneratorRequest_RequestedFile_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader
          .getStruct(defaultValue)
          .map(CodeGeneratorRequest_RequestedFile_Reader.new);

  int get id => reader.getUInt64(0, 0);

  bool get hasFilename => !reader.getPointer(0).isNull;
  String get filename => reader.getPointer(0).getText(null).unwrap();

  bool get hasImports => !reader.getPointer(1).isNull;
  StructListReader<CodeGeneratorRequest_RequestedFile_Import_Reader>
      get imports {
    return StructListReader.fromPointer(
      reader.getPointer(1),
      CodeGeneratorRequest_RequestedFile_Import_Reader.new,
      null,
    ).unwrap();
  }

  @override
  String toString() =>
      '(id = $id, filename = $filename, imports = [${imports.join(', ')}])';
}

// CodeGeneratorRequest.RequestedFile.Import

final class CodeGeneratorRequest_RequestedFile_Import_Reader
    extends CapnpStructReader {
  const CodeGeneratorRequest_RequestedFile_Import_Reader(super.reader);

  static CapnpResult<CodeGeneratorRequest_RequestedFile_Import_Reader>
      fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
          reader
              .getStruct(defaultValue)
              .map(CodeGeneratorRequest_RequestedFile_Import_Reader.new);

  int get id => reader.getUInt64(0, 0);

  bool get hasName => !reader.getPointer(0).isNull;
  String get name => reader.getPointer(0).getText(null).unwrap();

  @override
  String toString() => '(id = $id, name = $name)';
}
