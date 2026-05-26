import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Returns a fresh RFC 4122 v4 UUID.
///
/// Slice 2 uses this to mint local Stop ids before the backend `routes`
/// table exists. Slice 3's HttpStopsRepository will keep the same id
/// space — the backend trusts the client-minted id on first POST.
String newId() => _uuid.v4();
