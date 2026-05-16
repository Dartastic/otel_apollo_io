// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_apollo_io/otel_apollo_io.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_apollo_io-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('phone.reveal records mobile credit + verification', () async {
    await tracedApolloIo<String>(
      operation: 'phone.reveal',
      invoke: () async => const ApolloIoCallResult(
        value: 'ok',
        result: ApolloIoResult(
          contactId: 'c_1',
          entityKind: 'phone',
          matchStatus: 'matched',
          phoneStatus: 'verified',
          creditsMobile: 1,
          rateLimitRemaining: 199,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('apollo_io phone.reveal')!);
    expect(a['apollo_io.match.status'], 'matched');
    expect(a['apollo_io.phone.status'], 'verified');
    expect(a['apollo_io.credits.mobile'], 1);
    expect(a['apollo_io.rate_limit.remaining'], 199);
  });

  test('emails.find records email credits + verification', () async {
    await tracedApolloIo<String>(
      operation: 'emails.find',
      invoke: () async => const ApolloIoCallResult(
        value: 'ok',
        result: ApolloIoResult(
          contactId: 'c_2',
          entityKind: 'email',
          matchStatus: 'matched',
          emailStatus: 'likely_to_engage',
          creditsEmailFinder: 1,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('apollo_io emails.find')!);
    expect(a['apollo_io.email.status'], 'likely_to_engage');
    expect(a['apollo_io.credits.email_finder'], 1);
  });

  test('HTTP 402 sets span error', () async {
    await tracedApolloIo<String>(
      operation: 'people.search',
      invoke: () async => const ApolloIoCallResult(
        value: 'ok',
        result: ApolloIoResult(statusCode: 402),
      ),
    );
    expect(
      spans.findSpanByName('apollo_io people.search')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutApolloIoInstrumentationAsync(() async {
      await tracedApolloIo<String>(
        operation: 'usage.list',
        invoke: () async => const ApolloIoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('apollo_io '), isEmpty);
  });
}
