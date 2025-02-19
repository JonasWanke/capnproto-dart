// ignore_for_file: camel_case_types

import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';

// Node

class Node_Reader extends CapnpStructReader {
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

  Node_union_Reader get which {
    return switch (reader.getUInt16(6, 0)) {
      0 => Node_file_Reader(reader),
      1 => Node_struct_Reader(reader),
      2 => Node_enum_Reader(reader),
      3 => Node_interface_Reader(reader),
      4 => Node_const_Reader(reader),
      5 => Node_annotation_Reader(reader),
      _ => Node_notInSchema_Reader(reader),
    };
  }

  @override
  String toString() {
    return '(id = $id, displayName = $displayName, '
        'displayNamePrefixLength = $displayNamePrefixLength, '
        'scopeId = $scopeId, isGeneric = $isGeneric)';
  }
}

sealed class Node_union_Reader extends CapnpStructReader {
  const Node_union_Reader(super.reader);
}

class Node_file_Reader extends Node_union_Reader {
  const Node_file_Reader(super.reader);

  @override
  String toString() => '(file = ())';
}

class Node_struct_Reader extends Node_union_Reader {
  const Node_struct_Reader(super.reader);

  int get dataWordCount => reader.getUInt16(7, 0);

  int get pointerCount => reader.getUInt16(12, 0);

  ElementSize get preferredListEncoding =>
      ElementSize.fromValue(reader.getUInt16(13, 0));

  bool get isGroup => reader.getBool(224, false);

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

class Node_enum_Reader extends Node_union_Reader {
  const Node_enum_Reader(super.reader);

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

class Node_interface_Reader extends Node_union_Reader {
  const Node_interface_Reader(super.reader);

  // TODO(JonasWanke): methods, superclasses

  @override
  String toString() => '(interface = ())';
}

class Node_const_Reader extends Node_union_Reader {
  const Node_const_Reader(super.reader);

  bool get hasType => !reader.getPointer(3).isNull;
  Type_Reader get type =>
      Type_Reader(reader.getPointer(3).getStruct(null).unwrap());

  Value_Reader get value =>
      Value_Reader(reader.getPointer(4).getStruct(null).unwrap());

  @override
  String toString() => '(const = (type = $type, value = $value))';
}

class Node_annotation_Reader extends Node_union_Reader {
  const Node_annotation_Reader(super.reader);

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

class Node_notInSchema_Reader extends Node_union_Reader {
  const Node_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Node.Parameter

class Node_Parameter_Reader extends CapnpStructReader {
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

class Node_NestedNode_Reader extends CapnpStructReader {
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

class Node_SourceInfo_Reader extends CapnpStructReader {
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

class Node_SourceInfo_Member_Reader extends CapnpStructReader {
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

class Field_Reader extends CapnpStructReader {
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

  static const defaultDiscriminantValue = 65535;
  int get discriminantValue => reader.getUInt16(1, defaultDiscriminantValue);

  Field_union_Reader get which {
    return switch (reader.getUInt16(4, 0)) {
      0 => Field_slot_Reader(reader),
      1 => Field_group_Reader(reader),
      _ => Field_notInSchema_Reader(reader),
    };
  }

  Field_Ordinal_union_Reader get ordinal {
    return switch (reader.getUInt16(5, 0)) {
      0 => Field_Ordinal_implicit_Reader(reader),
      1 => Field_Ordinal_explicit_Reader(reader),
      _ => Field_Ordinal_notInSchema_Reader(reader),
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

sealed class Field_union_Reader extends CapnpStructReader {
  const Field_union_Reader(super.reader);
}

class Field_slot_Reader extends Field_union_Reader {
  const Field_slot_Reader(super.reader);

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

class Field_group_Reader extends Field_union_Reader {
  const Field_group_Reader(super.reader);

  int get typeId => reader.getUInt64(2, 0);

  @override
  String toString() => '(group = (typeId = $typeId))';
}

class Field_notInSchema_Reader extends Field_union_Reader {
  const Field_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

sealed class Field_Ordinal_union_Reader extends CapnpStructReader {
  const Field_Ordinal_union_Reader(super.reader);
}

class Field_Ordinal_implicit_Reader extends Field_Ordinal_union_Reader {
  const Field_Ordinal_implicit_Reader(super.reader);

  @override
  String toString() => '(implicit = ())';
}

class Field_Ordinal_explicit_Reader extends Field_Ordinal_union_Reader {
  const Field_Ordinal_explicit_Reader(super.reader);

  int get value => reader.getUInt16(6, 0);

  @override
  String toString() => '(explicit = $value)';
}

class Field_Ordinal_notInSchema_Reader extends Field_Ordinal_union_Reader {
  const Field_Ordinal_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Node.SourceInfo.Member

class Enumerant_Reader extends CapnpStructReader {
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

class Type_Reader extends CapnpStructReader {
  const Type_Reader(super.reader);

  static CapnpResult<Type_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Type_Reader.new);

  Type_union_Reader get which {
    return switch (reader.getUInt16(0, 0)) {
      0 => Type_void_Reader(reader),
      1 => Type_bool_Reader(reader),
      2 => Type_int8_Reader(reader),
      3 => Type_int16_Reader(reader),
      4 => Type_int32_Reader(reader),
      5 => Type_int64_Reader(reader),
      6 => Type_uint8_Reader(reader),
      7 => Type_uint16_Reader(reader),
      8 => Type_uint32_Reader(reader),
      9 => Type_uint64_Reader(reader),
      10 => Type_float32_Reader(reader),
      11 => Type_float64_Reader(reader),
      12 => Type_text_Reader(reader),
      13 => Type_data_Reader(reader),
      14 => Type_list_Reader(reader),
      15 => Type_enum_Reader(reader),
      16 => Type_struct_Reader(reader),
      17 => Type_interface_Reader(reader),
      18 => Type_anyPointer_Reader(reader),
      _ => Type_notInSchema_Reader(reader),
    };
  }

  @override
  String toString() => '($which)';
}

sealed class Type_union_Reader extends CapnpStructReader {
  const Type_union_Reader(super.reader);
}

class Type_void_Reader extends Type_union_Reader {
  const Type_void_Reader(super.reader);

  @override
  String toString() => '(void = ())';
}

class Type_bool_Reader extends Type_union_Reader {
  const Type_bool_Reader(super.reader);

  @override
  String toString() => '(bool = ())';
}

class Type_int8_Reader extends Type_union_Reader {
  const Type_int8_Reader(super.reader);

  @override
  String toString() => '(int8 = ())';
}

class Type_int16_Reader extends Type_union_Reader {
  const Type_int16_Reader(super.reader);

  @override
  String toString() => '(int16 = ())';
}

class Type_int32_Reader extends Type_union_Reader {
  const Type_int32_Reader(super.reader);

  @override
  String toString() => '(int32 = ())';
}

class Type_int64_Reader extends Type_union_Reader {
  const Type_int64_Reader(super.reader);

  @override
  String toString() => '(int64 = ())';
}

class Type_uint8_Reader extends Type_union_Reader {
  const Type_uint8_Reader(super.reader);

  @override
  String toString() => '(uint8 = ())';
}

class Type_uint16_Reader extends Type_union_Reader {
  const Type_uint16_Reader(super.reader);

  @override
  String toString() => '(uint16 = ())';
}

class Type_uint32_Reader extends Type_union_Reader {
  const Type_uint32_Reader(super.reader);

  @override
  String toString() => '(uint32 = ())';
}

class Type_uint64_Reader extends Type_union_Reader {
  const Type_uint64_Reader(super.reader);

  @override
  String toString() => '(uint64 = ())';
}

class Type_float32_Reader extends Type_union_Reader {
  const Type_float32_Reader(super.reader);

  @override
  String toString() => '(float32 = ())';
}

class Type_float64_Reader extends Type_union_Reader {
  const Type_float64_Reader(super.reader);

  @override
  String toString() => '(float64 = ())';
}

class Type_text_Reader extends Type_union_Reader {
  const Type_text_Reader(super.reader);

  @override
  String toString() => '(text = ())';
}

class Type_data_Reader extends Type_union_Reader {
  const Type_data_Reader(super.reader);

  @override
  String toString() => '(data = ())';
}

class Type_list_Reader extends Type_union_Reader {
  const Type_list_Reader(super.reader);

  bool get hasElementType => !reader.getPointer(0).isNull;
  Type_Reader get elementType =>
      Type_Reader(reader.getPointer(0).getStruct(null).unwrap());

  @override
  String toString() => '(list = (elementType = $elementType))';
}

class Type_enum_Reader extends Type_union_Reader {
  const Type_enum_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(enum = (typeId = $typeId))';
}

class Type_struct_Reader extends Type_union_Reader {
  const Type_struct_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(struct = (typeId = $typeId))';
}

class Type_interface_Reader extends Type_union_Reader {
  const Type_interface_Reader(super.reader);

  int get typeId => reader.getUInt64(1, 0);

  // TODO(JonasWanke): brand

  @override
  String toString() => '(interface = (typeId = $typeId))';
}

class Type_anyPointer_Reader extends Type_union_Reader {
  const Type_anyPointer_Reader(super.reader);

  // TODO(JonasWanke): union

  @override
  String toString() => '(anyPointer = ())';
}

class Type_notInSchema_Reader extends Type_union_Reader {
  const Type_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Value

class Value_Reader extends CapnpStructReader {
  const Value_Reader(super.reader);

  static CapnpResult<Value_Reader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getStruct(defaultValue).map(Value_Reader.new);

  Value_union_Reader get which {
    return switch (reader.getUInt16(0, 0)) {
      0 => Value_void_Reader(reader),
      1 => Value_bool_Reader(reader),
      2 => Value_int8_Reader(reader),
      3 => Value_int16_Reader(reader),
      4 => Value_int32_Reader(reader),
      5 => Value_int64_Reader(reader),
      6 => Value_uint8_Reader(reader),
      7 => Value_uint16_Reader(reader),
      8 => Value_uint32_Reader(reader),
      9 => Value_uint64_Reader(reader),
      10 => Value_float32_Reader(reader),
      11 => Value_float64_Reader(reader),
      12 => Value_text_Reader(reader),
      13 => Value_data_Reader(reader),
      14 => Value_list_Reader(reader),
      15 => Value_enum_Reader(reader),
      16 => Value_struct_Reader(reader),
      17 => Value_interface_Reader(reader),
      18 => Value_anyPointer_Reader(reader),
      _ => Value_notInSchema_Reader(reader),
    };
  }

  @override
  String toString() => '($which)';
}

sealed class Value_union_Reader extends CapnpStructReader {
  const Value_union_Reader(super.reader);
}

class Value_void_Reader extends Value_union_Reader {
  const Value_void_Reader(super.reader);

  void get value {}

  @override
  String toString() => 'void = ()';
}

class Value_bool_Reader extends Value_union_Reader {
  const Value_bool_Reader(super.reader);

  bool get value => reader.getBool(16, false);

  @override
  String toString() => 'bool = $value';
}

class Value_int8_Reader extends Value_union_Reader {
  const Value_int8_Reader(super.reader);

  int get value => reader.getInt8(2, 0);

  @override
  String toString() => 'int8 = $value';
}

class Value_int16_Reader extends Value_union_Reader {
  const Value_int16_Reader(super.reader);

  int get value => reader.getInt16(1, 0);

  @override
  String toString() => 'int16 = $value';
}

class Value_int32_Reader extends Value_union_Reader {
  const Value_int32_Reader(super.reader);

  int get value => reader.getInt32(1, 0);

  @override
  String toString() => 'int32 = $value';
}

class Value_int64_Reader extends Value_union_Reader {
  const Value_int64_Reader(super.reader);

  int get value => reader.getInt64(1, 0);

  @override
  String toString() => 'int64 = $value';
}

class Value_uint8_Reader extends Value_union_Reader {
  const Value_uint8_Reader(super.reader);

  int get value => reader.getUInt8(2, 0);

  @override
  String toString() => 'uint8 = $value';
}

class Value_uint16_Reader extends Value_union_Reader {
  const Value_uint16_Reader(super.reader);

  int get value => reader.getUInt16(1, 0);

  @override
  String toString() => 'uint16 = $value';
}

class Value_uint32_Reader extends Value_union_Reader {
  const Value_uint32_Reader(super.reader);

  int get value => reader.getUInt32(1, 0);

  @override
  String toString() => 'uint32 = $value';
}

class Value_uint64_Reader extends Value_union_Reader {
  const Value_uint64_Reader(super.reader);

  int get value => reader.getUInt64(1, 0);

  @override
  String toString() => 'uint64 = $value';
}

class Value_float32_Reader extends Value_union_Reader {
  const Value_float32_Reader(super.reader);

  double get value => reader.getFloat32(1, 0);

  @override
  String toString() => 'float32 = $value';
}

class Value_float64_Reader extends Value_union_Reader {
  const Value_float64_Reader(super.reader);

  double get value => reader.getFloat64(1, 0);

  @override
  String toString() => 'float64 = $value';
}

class Value_text_Reader extends Value_union_Reader {
  const Value_text_Reader(super.reader);

  String get value => reader.getPointer(0).getText(null).unwrap();

  @override
  String toString() => 'text = $value';
}

class Value_data_Reader extends Value_union_Reader {
  const Value_data_Reader(super.reader);

  ByteData get value => reader.getPointer(0).getData(null).unwrap();

  @override
  String toString() => 'data = $value';
}

class Value_list_Reader extends Value_union_Reader {
  const Value_list_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'list = $value';
}

class Value_enum_Reader extends Value_union_Reader {
  const Value_enum_Reader(super.reader);

  int get value => reader.getUInt16(1, 0);

  @override
  String toString() => 'enum = $value';
}

class Value_struct_Reader extends Value_union_Reader {
  const Value_struct_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'struct = $value';
}

class Value_interface_Reader extends Value_union_Reader {
  const Value_interface_Reader(super.reader);

  @override
  String toString() => 'interface = ()';
}

class Value_anyPointer_Reader extends Value_union_Reader {
  const Value_anyPointer_Reader(super.reader);

  AnyPointerReader get value => AnyPointerReader(reader.getPointer(0));

  @override
  String toString() => 'anyPointer = $value';
}

class Value_notInSchema_Reader extends Value_union_Reader {
  const Value_notInSchema_Reader(super.reader);

  @override
  String toString() => '<not in schema>';
}

// Annotation

class Annotation_Reader extends CapnpStructReader {
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

class CapnpVersion_Reader extends CapnpStructReader {
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

class CodeGeneratorRequest_Reader extends CapnpStructReader {
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

class CodeGeneratorRequest_RequestedFile_Reader extends CapnpStructReader {
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

class CodeGeneratorRequest_RequestedFile_Import_Reader
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
