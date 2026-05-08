// Reference template for mobile DTOs that mirror backend TypeBox schemas.
// See ADR-0013 (docs/decisions/0013-api-contract-source-of-truth.md) and
// docs/02-ARCHITECTURE.md (API Contracts & Type Safety).
//
// Convention:
//   1. Every DTO file lives at apps/mobile/lib/features/<feature>/data/dto/
//      and starts with a header of the form:
//        // Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>
//   2. Field names and types match the TypeBox schema 1:1. No renaming.
//   3. fromJson / toJson are explicit until OpenAPI codegen lands post-M1.
//   4. Validation is server-side only; the DTO trusts the wire payload.
//   5. When the TypeBox schema changes, this file changes in the same commit.
//
// This file is a reference only. It exports nothing public; the analyzer
// would otherwise warn about unused private elements.

// ignore_for_file: unused_element

/// Mirror of: `apps/backend/src/<feature>/schemas.ts` -> `ExampleResponseSchema`
class _ExampleDto {
  const _ExampleDto({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String email;
  final DateTime createdAt;

  factory _ExampleDto.fromJson(Map<String, dynamic> json) {
    return _ExampleDto(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };
}
