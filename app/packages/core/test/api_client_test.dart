import 'dart:io';

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

/// Local server mimicking the backend: Protobuf bodies, gzip, weak ETag on /lineas.
void main() {
  late HttpServer server;
  late ApiClient api;
  var linesHits = 0;

  final lines = pb.Lines(lines: [for (var i = 0; i < 60; i++) pb.Line(id: 'linea-$i', name: 'Línea número $i')]);
  const etag = 'W/"abc"';

  setUp(() async {
    linesHits = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.autoCompress = false;
    server.listen((req) async {
      final res = req.response;
      res.headers.contentType = ContentType('application', 'x-protobuf');
      switch (req.uri.path) {
        case '/lineas':
          linesHits++;
          if (req.headers.value(HttpHeaders.ifNoneMatchHeader) == etag) {
            res.statusCode = HttpStatus.notModified;
          } else {
            res.headers.set(HttpHeaders.etagHeader, etag);
            res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
            res.add(gzip.encode(lines.writeToBuffer()));
          }
        case '/ruta':
          if (req.uri.queryParameters['veh'] == '404') {
            res.statusCode = HttpStatus.notFound;
          } else {
            res.add(pb.Route(polyline: '_p~iF~ps|U', distM: 1200, timeS: 180).writeToBuffer());
          }
        case '/auth/chofer':
          final login = pb.DriverLogin.fromBuffer(await req.fold<List<int>>([], (a, b) => a..addAll(b)));
          if (login.pin == '4821') {
            res.add(pb.Token(jwt: 'jwt-${login.veh}-${login.line}', exp: 99).writeToBuffer());
          } else {
            res.statusCode = HttpStatus.unauthorized;
          }
        default:
          res.statusCode = HttpStatus.notFound;
      }
      await res.close();
    });
    api = ApiClient(Uri.parse('http://127.0.0.1:${server.port}'));
  });

  tearDown(() async {
    api.close();
    await server.close(force: true);
  });

  test('lines: gunzips, then revalidates with the ETag and reuses the cache on 304', () async {
    final first = await api.lines();
    expect(first, hasLength(60));
    final afterFirst = api.usage.httpRx;

    final second = await api.lines();
    expect(second, same(first));
    expect(linesHits, 2);
    expect(api.usage.httpRx - afterFirst, lessThan(afterFirst ~/ 2), reason: '304 costs only headers');
  });

  test('counts compressed bytes, not decompressed', () async {
    await api.lines();
    final gz = gzip.encode(lines.writeToBuffer()).length;
    expect(api.usage.httpRx, greaterThanOrEqualTo(gz));
    expect(api.usage.httpRx, lessThan(lines.writeToBuffer().length + 400));
    expect(api.usage.httpTx, greaterThan(0));
  });

  test('route returns null when the vehicle is not live', () async {
    expect((await api.route(7, const GeoPoint(10.64, -71.61)))!.distM, 1200);
    expect(await api.route(404, const GeoPoint(10.64, -71.61)), isNull);
  });

  test('driver token, and ApiException with the status on a wrong PIN', () async {
    final t = await api.driverToken(veh: 7, pin: '4821', line: 'santa-rosa');
    expect(t.jwt, 'jwt-7-santa-rosa');
    await expectLater(api.driverToken(veh: 7, pin: '0000', line: 'santa-rosa'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
  });
}
