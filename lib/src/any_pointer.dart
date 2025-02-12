import 'error.dart';
import 'message.dart';
import 'private/layout.dart';
import 'reader_builder.dart';

final class AnyPointerReader extends CapnpReader {
  AnyPointerReader(this.reader);

  final PointerReader reader;

  CapnpResult<R> getAs<R extends CapnpReader>(
    FromPointerReader<R> fromPointer,
  ) =>
      fromPointer(reader, null);
}

final class AnyPointerBuilder extends CapnpBuilder<AnyPointerReader> {
  AnyPointerBuilder(this.builder);

  final PointerBuilder builder;

  @override
  AnyPointerReader get asReader => AnyPointerReader(builder.asReader);

  CapnpResult<B> getAs<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
  ) =>
      fromPointer.getFromPointer(builder, null);
  B initAs<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
  ) =>
      fromPointer.initPointer(builder, 0);
  B initAsListOf<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
    int length,
  ) =>
      fromPointer.initPointer(builder, length);

  // TODO(JonasWanke): setAs(…)
}
