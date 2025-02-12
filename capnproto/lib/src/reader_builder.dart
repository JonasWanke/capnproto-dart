abstract base class CapnpReader {
  const CapnpReader();
}

abstract base class CapnpBuilder<R extends CapnpReader> {
  const CapnpBuilder();

  R get asReader;
}
