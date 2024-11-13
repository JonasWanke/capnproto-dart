import 'dart:typed_data';

import '../objects/list.dart';
import '../objects/struct.dart';
import '../pointer.dart';

// TODO(JonasWanke): add `toString()`

// Node

class Node extends Struct {
  const Node(super.reader);

  int get id => reader.getUInt64(0);
  String get displayName => reader.getText(0);
  int get displayNamePrefixLength => reader.getUInt32(2);
  int get scopeId => reader.getUInt64(2);
  CompositeList<Node$Parameter> get parameters =>
      reader.getCompositeList(5, Node$Parameter.new);
  bool get isGeneric => reader.getBool(288);
  CompositeList<Node$NestedNode> get nestedNodes =>
      reader.getCompositeList(1, Node$NestedNode.new);
  CompositeList<Annotation> get annotations =>
      reader.getCompositeList(2, Annotation.new);
  Node$union get union => Node$union(reader);
}

sealed class Node$union extends Struct {
  factory Node$union(StructReader reader) {
    final tag = reader.getUInt16(6);
    return switch (tag) {
      0 => Node$file(reader),
      1 => Node$struct(reader),
      2 => Node$enum(reader),
      3 => Node$interface(reader),
      4 => Node$const(reader),
      5 => Node$annotation(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Node$union._(super.reader);
}

class Node$file extends Node$union {
  const Node$file(super.reader) : super._();
}

class Node$struct extends Node$union {
  const Node$struct(super.reader) : super._();

  int get dataWordCount => reader.getUInt16(7);
  int get readerCount => reader.getUInt16(12);
  ElementSize get preferredListEncoding =>
      ElementSize.values[reader.getUInt16(14)];
  // TODO(JonasWanke): check enum DX
  bool get isGroup => reader.getBool(224);
  int get discriminantCount => reader.getUInt16(15);
  int get discriminantOffset => reader.getUInt32(6);
  CompositeList<Field> get fields => reader.getCompositeList(3, Field.new);
}

class Node$enum extends Node$union {
  const Node$enum(super.reader) : super._();

  CompositeList<Enumerant> get enumerants =>
      reader.getCompositeList(3, Enumerant.new);
}

class Node$interface extends Node$union {
  const Node$interface(super.reader) : super._();

  List<Method> get methods => reader.getCompositeList(3, Method.new);
  List<Superclass> get superclasses =>
      reader.getCompositeList(4, Superclass.new);
}

class Node$const extends Node$union {
  const Node$const(super.reader) : super._();

  Type get type => reader.getStruct(3, Type.new);
  Value get value => reader.getStruct(4, Value.new);
}

class Node$annotation extends Node$union {
  const Node$annotation(super.reader) : super._();

  Type get type => reader.getStruct(3, Type.new);
  bool get targetsFile => reader.getBool(112);
  bool get targetsConst => reader.getBool(113);
  bool get targetsEnum => reader.getBool(114);
  bool get targetsEnumerant => reader.getBool(115);
  bool get targetsStruct => reader.getBool(116);
  bool get targetsField => reader.getBool(117);
  bool get targetsUnion => reader.getBool(118);
  bool get targetsGroup => reader.getBool(119);
  bool get targetsInterface => reader.getBool(120);
  bool get targetsMethod => reader.getBool(121);
  bool get targetsParam => reader.getBool(122);
  bool get targetsAnnotation => reader.getBool(123);
}

// Node.Parameter

class Node$Parameter extends Struct {
  const Node$Parameter(super.reader);

  String get name => reader.getText(0);
}

// Node.NestedNode

class Node$NestedNode extends Struct {
  const Node$NestedNode(super.reader);

  String get name => reader.getText(0);
  int get id => reader.getUInt64(0);
}

// Node.SourceInfo

class Node$SourceInfo extends Struct {
  const Node$SourceInfo(super.reader);

  int get id => reader.getUInt64(0);
  String get docComment => reader.getText(0);
  CompositeList<Node$SourceInfo$Member> get members =>
      reader.getCompositeList(1, Node$SourceInfo$Member.new);
}

// Node.SourceInfo.Member

class Node$SourceInfo$Member extends Struct {
  const Node$SourceInfo$Member(super.reader);

  String get docComment => reader.getText(0);
}

// Field

class Field extends Struct {
  const Field(super.reader);

  String get name => reader.getText(0);
  int get codeOrder => reader.getUInt16(0);
  CompositeList<Annotation> get annotations =>
      reader.getCompositeList(1, Annotation.new);
  int get discriminantValue => reader.getUInt16(0, defaultValue: 65535);
  Field$union get union => Field$union(reader);
}

sealed class Field$union extends Struct {
  factory Field$union(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Field$slot(reader),
      1 => Field$group(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Field$union._(super.reader);
}

class Field$slot extends Field$union {
  const Field$slot(super.reader) : super._();

  int get offset => reader.getUInt32(1);
  Type get type => reader.getStruct(2, Type.new);
  Value get defaultValue => reader.getStruct(3, Value.new);
  bool get hadExplicitDefault => reader.getBool(128);
}

class Field$group extends Field$union {
  const Field$group(super.reader) : super._();

  int get typeId => reader.getUInt64(2);
}

sealed class Field$ordinal extends Struct {
  factory Field$ordinal(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Field$ordinal$implicit(reader),
      1 => Field$ordinal$explicit(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Field$ordinal._(super.reader);
}

class Field$ordinal$implicit extends Field$ordinal {
  const Field$ordinal$implicit(super.reader) : super._();
}

class Field$ordinal$explicit extends Field$ordinal {
  const Field$ordinal$explicit(super.reader) : super._();

  int get value => reader.getUInt16(6);
}

// Enumerant

class Enumerant extends Struct {
  const Enumerant(super.reader);

  String get name => reader.getText(0);
  int get codeOrder => reader.getUInt16(0);
  CompositeList<Annotation> get annotations =>
      reader.getCompositeList(1, Annotation.new);
}

// Superclass

class Superclass extends Struct {
  const Superclass(super.reader);

  int get id => reader.getUInt64(0);
  Brand get brand => reader.getStruct(0, Brand.new);
}

// Method

class Method extends Struct {
  const Method(super.reader);

  String get name => reader.getText(0);
  int get codeOrder => reader.getUInt16(0);
  CompositeList<Node$Parameter> get implicitParameters =>
      reader.getCompositeList(4, Node$Parameter.new);
  int get paramStructType => reader.getUInt64(1);
  Brand get paramBrand => reader.getStruct(2, Brand.new);
  int get resultStructType => reader.getUInt64(2);
  Brand get resultBrand => reader.getStruct(3, Brand.new);
  CompositeList<Annotation> get annotations =>
      reader.getCompositeList(1, Annotation.new);
}

// Type

sealed class Type extends Struct {
  factory Type(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Type$void(reader),
      1 => Type$bool(reader),
      2 => Type$int8(reader),
      3 => Type$int16(reader),
      4 => Type$int32(reader),
      5 => Type$int64(reader),
      6 => Type$uint8(reader),
      7 => Type$uint16(reader),
      8 => Type$uint32(reader),
      9 => Type$uint64(reader),
      10 => Type$float32(reader),
      11 => Type$float64(reader),
      12 => Type$text(reader),
      13 => Type$data(reader),
      14 => Type$list(reader),
      15 => Type$enum(reader),
      16 => Type$struct(reader),
      17 => Type$interface(reader),
      18 => Type$anyPointer(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Type._(super.reader);
}

class Type$void extends Type {
  const Type$void(super.reader) : super._();
}

class Type$bool extends Type {
  const Type$bool(super.reader) : super._();
}

class Type$int8 extends Type {
  const Type$int8(super.reader) : super._();
}

class Type$int16 extends Type {
  const Type$int16(super.reader) : super._();
}

class Type$int32 extends Type {
  const Type$int32(super.reader) : super._();
}

class Type$int64 extends Type {
  const Type$int64(super.reader) : super._();
}

class Type$uint8 extends Type {
  const Type$uint8(super.reader) : super._();
}

class Type$uint16 extends Type {
  const Type$uint16(super.reader) : super._();
}

class Type$uint32 extends Type {
  const Type$uint32(super.reader) : super._();
}

class Type$uint64 extends Type {
  const Type$uint64(super.reader) : super._();
}

class Type$float32 extends Type {
  const Type$float32(super.reader) : super._();
}

class Type$float64 extends Type {
  const Type$float64(super.reader) : super._();
}

class Type$text extends Type {
  const Type$text(super.reader) : super._();
}

class Type$data extends Type {
  const Type$data(super.reader) : super._();
}

class Type$list extends Type {
  const Type$list(super.reader) : super._();

  Type get elementType => reader.getStruct(0, Type.new);
}

class Type$enum extends Type {
  const Type$enum(super.reader) : super._();

  int get typeId => reader.getUInt64(1);
  Brand get brand => reader.getStruct(0, Brand.new);
}

class Type$struct extends Type {
  const Type$struct(super.reader) : super._();

  int get typeId => reader.getUInt64(1);
  Brand get brand => reader.getStruct(0, Brand.new);
}

class Type$interface extends Type {
  const Type$interface(super.reader) : super._();

  int get typeId => reader.getUInt64(1);
  Brand get brand => reader.getStruct(0, Brand.new);
}

sealed class Type$anyPointer extends Type {
  factory Type$anyPointer(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Type$anyPointer$unconstrained(reader),
      1 => Type$anyPointer$parameter(reader),
      2 => Type$anyPointer$implicitMethodParameter(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Type$anyPointer._(super.reader) : super._();
}

sealed class Type$anyPointer$unconstrained extends Type$anyPointer {
  factory Type$anyPointer$unconstrained(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Type$anyPointer$unconstrained$anyKind(reader),
      1 => Type$anyPointer$unconstrained$struct(reader),
      2 => Type$anyPointer$unconstrained$list(reader),
      3 => Type$anyPointer$unconstrained$capability(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Type$anyPointer$unconstrained._(super.reader) : super._();
}

class Type$anyPointer$unconstrained$anyKind
    extends Type$anyPointer$unconstrained {
  const Type$anyPointer$unconstrained$anyKind(super.reader) : super._();
}

class Type$anyPointer$unconstrained$struct
    extends Type$anyPointer$unconstrained {
  const Type$anyPointer$unconstrained$struct(super.reader) : super._();
}

class Type$anyPointer$unconstrained$list extends Type$anyPointer$unconstrained {
  const Type$anyPointer$unconstrained$list(super.reader) : super._();
}

class Type$anyPointer$unconstrained$capability
    extends Type$anyPointer$unconstrained {
  const Type$anyPointer$unconstrained$capability(super.reader) : super._();
}

class Type$anyPointer$parameter extends Type$anyPointer {
  const Type$anyPointer$parameter(super.reader) : super._();

  int get scopeId => reader.getUInt64(2);
  int get parameterIndex => reader.getUInt16(5);
}

class Type$anyPointer$implicitMethodParameter extends Type$anyPointer {
  const Type$anyPointer$implicitMethodParameter(super.reader) : super._();

  int get parameterIndex => reader.getUInt16(5);
}

// Brand

class Brand extends Struct {
  const Brand(super.reader);

  CompositeList<Brand$Scope> get scopes =>
      reader.getCompositeList(0, Brand$Scope.new);
}

// Brand.Scope

class Brand$Scope extends Struct {
  const Brand$Scope(super.reader);

  int get scopeId => reader.getUInt64(0);
  Brand$Scope$union get union => Brand$Scope$union(reader);
}

sealed class Brand$Scope$union extends Struct {
  factory Brand$Scope$union(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Brand$Scope$bind(reader),
      1 => Brand$Scope$inherit(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Brand$Scope$union._(super.reader);
}

class Brand$Scope$bind extends Brand$Scope$union {
  const Brand$Scope$bind(super.reader) : super._();

  CompositeList<Brand$Binding> get bindings =>
      reader.getCompositeList(1, Brand$Binding.new);
}

class Brand$Scope$inherit extends Brand$Scope$union {
  const Brand$Scope$inherit(super.reader) : super._();
}

// Brand.Binding

sealed class Brand$Binding extends Struct {
  factory Brand$Binding(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Brand$Binding$unbound(reader),
      1 => Brand$Binding$type(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Brand$Binding._(super.reader);
}

class Brand$Binding$unbound extends Brand$Binding {
  const Brand$Binding$unbound(super.reader) : super._();
}

class Brand$Binding$type extends Brand$Binding {
  const Brand$Binding$type(super.reader) : super._();

  Type get type => reader.getStruct(0, Type.new);
}

// Value

sealed class Value extends Struct {
  factory Value(StructReader reader) {
    final tag = reader.getUInt16(0);
    return switch (tag) {
      0 => Value$void(reader),
      1 => Value$bool(reader),
      2 => Value$int8(reader),
      3 => Value$int16(reader),
      4 => Value$int32(reader),
      5 => Value$int64(reader),
      6 => Value$uint8(reader),
      7 => Value$uint16(reader),
      8 => Value$uint32(reader),
      9 => Value$uint64(reader),
      10 => Value$float32(reader),
      11 => Value$float64(reader),
      12 => Value$text(reader),
      13 => Value$data(reader),
      14 => Value$list(reader),
      15 => Value$enum(reader),
      16 => Value$struct(reader),
      17 => Value$interface(reader),
      18 => Value$anyPointer(reader),
      _ => throw ArgumentError.value(tag, 'tag'),
    };
  }
  const Value._(super.reader);
}

class Value$void extends Value {
  const Value$void(super.reader) : super._();
}

class Value$bool extends Value {
  const Value$bool(super.reader) : super._();
  bool get value => reader.getBool(16);
}

class Value$int8 extends Value {
  const Value$int8(super.reader) : super._();
  int get value => reader.getInt8(2);
}

class Value$int16 extends Value {
  const Value$int16(super.reader) : super._();
  int get value => reader.getInt16(1);
}

class Value$int32 extends Value {
  const Value$int32(super.reader) : super._();
  int get value => reader.getInt32(1);
}

class Value$int64 extends Value {
  const Value$int64(super.reader) : super._();
  int get value => reader.getInt64(1);
}

class Value$uint8 extends Value {
  const Value$uint8(super.reader) : super._();
  int get value => reader.getUInt8(2);
}

class Value$uint16 extends Value {
  const Value$uint16(super.reader) : super._();
  int get value => reader.getUInt16(1);
}

class Value$uint32 extends Value {
  const Value$uint32(super.reader) : super._();
  int get value => reader.getUInt32(1);
}

class Value$uint64 extends Value {
  const Value$uint64(super.reader) : super._();
  int get value => reader.getUInt64(1);
}

class Value$float32 extends Value {
  const Value$float32(super.reader) : super._();
  double get value => reader.getFloat32(1);
}

class Value$float64 extends Value {
  const Value$float64(super.reader) : super._();
  double get value => reader.getFloat64(1);
}

class Value$text extends Value {
  const Value$text(super.reader) : super._();
  String get value => reader.getText(0);
}

class Value$data extends Value {
  const Value$data(super.reader) : super._();
  Uint8List get value => reader.getData(0);
}

class Value$list extends Value {
  const Value$list(super.reader) : super._();
  AnyPointer get value => reader.getPointer(0);
}

class Value$enum extends Value {
  const Value$enum(super.reader) : super._();
  int get value => reader.getUInt16(1);
}

class Value$struct extends Value {
  const Value$struct(super.reader) : super._();
  AnyPointer get value => reader.getPointer(0);
}

class Value$interface extends Value {
  const Value$interface(super.reader) : super._();
  AnyPointer get value => reader.getPointer(0);
}

class Value$anyPointer extends Value {
  const Value$anyPointer(super.reader) : super._();
  AnyPointer get value => reader.getPointer(0);
}

// Annotation

class Annotation extends Struct {
  const Annotation(super.reader);

  int get id => reader.getUInt64(0);
  Brand get brand => reader.getStruct(1, Brand.new);
  Value get value => reader.getStruct(0, Value.new);
}

// ElementSize

enum ElementSize {
  empty,
  bit,
  byte,
  twoBytes,
  fourBytes,
  eightBytes,
  reader,
  inlineComposit,
}

// CapnpVersion

class CapnpVersion extends Struct {
  const CapnpVersion(super.reader);

  int get major => reader.getUInt16(0);
  int get minor => reader.getUInt8(2);
  int get micro => reader.getUInt8(3);
}

// CodeGeneratorRequest

class CodeGeneratorRequest extends Struct {
  const CodeGeneratorRequest(super.reader);

  CapnpVersion get capnpVersion => reader.getStruct(2, CapnpVersion.new);
  CompositeList<Node> get nodes => reader.getCompositeList(0, Node.new);
  CompositeList<Node$SourceInfo> get sourceInfo =>
      reader.getCompositeList(3, Node$SourceInfo.new);
  CompositeList<CodeGeneratorRequest$RequestedFile> get requestedFiles =>
      reader.getCompositeList(1, CodeGeneratorRequest$RequestedFile.new);
}

// CodeGeneratorRequest.RequestedFile

class CodeGeneratorRequest$RequestedFile extends Struct {
  const CodeGeneratorRequest$RequestedFile(super.reader);

  int get id => reader.getUInt64(0);
  String get filename => reader.getText(0);
  CompositeList<CodeGeneratorRequest$RequestedFile$Import> get imports =>
      reader.getCompositeList(
        0,
        CodeGeneratorRequest$RequestedFile$Import.new,
      );
}

// CodeGeneratorRequest.RequestedFile.Import

class CodeGeneratorRequest$RequestedFile$Import extends Struct {
  const CodeGeneratorRequest$RequestedFile$Import(super.reader);

  int get id => reader.getUInt64(0);
  String get filename => reader.getText(0);
}