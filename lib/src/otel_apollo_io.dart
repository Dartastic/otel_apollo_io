// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_apollo_io_suppression.dart';

const _tracerName = 'dartastic_otel_libs_apollo_io';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ApolloIoResult {
  const ApolloIoResult({
    this.organizationId,
    this.contactId,
    this.accountId,
    this.sequenceId,
    this.entityKind,
    this.matchStatus,
    this.emailStatus,
    this.phoneStatus,
    this.creditsEmailFinder,
    this.creditsExportLeads,
    this.creditsMobile,
    this.totalResults,
    this.rateLimitRemaining,
    this.statusCode,
  });

  /// Apollo organization (the account being researched / enriched).
  final String? organizationId;

  /// Apollo contact (person) id.
  final String? contactId;

  /// Apollo account (CRM-tracked company) id.
  final String? accountId;

  /// Sequence (Apollo's outbound sequence/cadence).
  final String? sequenceId;

  /// `person` / `organization` / `account` / `contact` / `email` /
  /// `phone` / `task` / `meeting`.
  final String? entityKind;

  /// `matched` / `unmatched` / `partial` — enrichment outcome.
  final String? matchStatus;

  /// `verified` / `likely_to_engage` / `unavailable` / `unverified` /
  /// `extrapolated`.
  final String? emailStatus;

  /// `verified` / `unverified` / `mobile_unavailable`.
  final String? phoneStatus;

  /// Credit dimensions — Apollo charges per:
  /// - `email_finder` credit per email revealed
  /// - `export_leads` credit per lead exported to CSV/CRM
  /// - `mobile` credit per mobile phone revealed (most expensive)
  final int? creditsEmailFinder;
  final int? creditsExportLeads;
  final int? creditsMobile;

  /// `pagination.total_entries` from People/Org search.
  final int? totalResults;

  final int? rateLimitRemaining;

  final int? statusCode;
}

class ApolloIoCallResult<T> {
  const ApolloIoCallResult({required this.value, this.result});
  final T value;
  final ApolloIoResult? result;
}

/// Wraps an Apollo.io API call in a CLIENT span. [operation] is one
/// of `people.search`, `organizations.search`, `people.match`,
/// `organizations.enrich`, `contacts.create`, `accounts.create`,
/// `sequences.add_contact`, `emails.find`, `phone.reveal`,
/// `tasks.create`, `meetings.create`, `usage.list`.
Future<T> tracedApolloIo<T>({
  required String operation,
  required Future<ApolloIoCallResult<T>> Function() invoke,
}) async {
  if (apolloIoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'apollo_io',
    'rpc.method': operation,
    'apollo_io.operation': operation,
  };

  final span = _tracer().startSpan(
    'apollo_io $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.organizationId != null) {
        extras.add(OTel.attributeString(
          'apollo_io.organization.id',
          r.result!.organizationId!,
        ));
      }
      if (r.result!.contactId != null) {
        extras.add(OTel.attributeString(
          'apollo_io.contact.id',
          r.result!.contactId!,
        ));
      }
      if (r.result!.accountId != null) {
        extras.add(OTel.attributeString(
          'apollo_io.account.id',
          r.result!.accountId!,
        ));
      }
      if (r.result!.sequenceId != null) {
        extras.add(OTel.attributeString(
          'apollo_io.sequence.id',
          r.result!.sequenceId!,
        ));
      }
      if (r.result!.entityKind != null) {
        extras.add(OTel.attributeString(
          'apollo_io.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.matchStatus != null) {
        extras.add(OTel.attributeString(
          'apollo_io.match.status',
          r.result!.matchStatus!,
        ));
      }
      if (r.result!.emailStatus != null) {
        extras.add(OTel.attributeString(
          'apollo_io.email.status',
          r.result!.emailStatus!,
        ));
      }
      if (r.result!.phoneStatus != null) {
        extras.add(OTel.attributeString(
          'apollo_io.phone.status',
          r.result!.phoneStatus!,
        ));
      }
      if (r.result!.creditsEmailFinder != null) {
        extras.add(OTel.attributeInt(
          'apollo_io.credits.email_finder',
          r.result!.creditsEmailFinder!,
        ));
      }
      if (r.result!.creditsExportLeads != null) {
        extras.add(OTel.attributeInt(
          'apollo_io.credits.export_leads',
          r.result!.creditsExportLeads!,
        ));
      }
      if (r.result!.creditsMobile != null) {
        extras.add(OTel.attributeInt(
          'apollo_io.credits.mobile',
          r.result!.creditsMobile!,
        ));
      }
      if (r.result!.totalResults != null) {
        extras.add(OTel.attributeInt(
          'apollo_io.total.results',
          r.result!.totalResults!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'apollo_io.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Apollo.io HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
