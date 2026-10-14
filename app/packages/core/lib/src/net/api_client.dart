import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../geo/geo.dart';
import '../proto/api.pb.dart';
import '../proto/auth.pb.dart';
import 'data_usage.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.path);

  final int statusCode;
  final String path;

  @override
  String toString() => 'ApiException($statusCode, $path)';
}

/// Backend HTTP client. Protobuf bodies, gzip handled here so [usage] sees the real wire size.
class ApiClient {
  ApiClient(this.baseUri, {HttpClient? http, DataUsage? usage, this.timeout = const Duration(seconds: 10)})
      : _http = (http ?? HttpClient())..autoUncompress = false,
        usage = usage ?? DataUsage();

  final Uri baseUri;
  final HttpClient _http;
  final DataUsage usage;
  final Duration timeout;

  String? _linesEtag;
  List<Line>? _lines;

  /// Active lines. Revalidated with If-None-Match; a 304 costs only headers.
  Future<List<Line>> lines() async {
    final res = await _send('GET', '/lineas', etag: _linesEtag);
    if (res.status == HttpStatus.notModified && _lines != null) return _lines!;
    _expect(res, '/lineas');
    _lines = Lines.fromBuffer(res.body).lines;
    _linesEtag = res.etag;
    return _lines!;
  }

  /// Seeds the ETag cache from persisted data (e.g. drift) so the first call can be a 304.
  void restoreLines(List<Line> lines, String etag) {
    _lines = lines;
    _linesEtag = etag;
  }

  String? get linesEtag => _linesEtag;

  Future<List<Nearby>> nearby(String line, GeoPoint user) async {
    final path = '/lineas/${Uri.encodeComponent(line)}/cercanos';
    final res = await _send('GET', path, query: {'lat': '${user.lat}', 'lon': '${user.lon}'});
    _expect(res, path);
    return NearbyList.fromBuffer(res.body).vehicles;
  }

  /// Null when the vehicle is no longer live (404) or no road route exists (422).
  Future<Route?> route(int veh, GeoPoint user) async {
    final res = await _send('GET', '/ruta', query: {'veh': '$veh', 'lat': '${user.lat}', 'lon': '${user.lon}'});
    if (res.status == HttpStatus.notFound || res.status == HttpStatus.unprocessableEntity) return null;
    _expect(res, '/ruta');
    return Route.fromBuffer(res.body);
  }

  /// Throws [ApiException] with 401 (wrong PIN), 404 (unknown line) or 429 (too many attempts).
  Future<Token> driverToken({required int veh, required String pin, required String line}) async {
    final body = DriverLogin(veh: veh, pin: pin, line: line).writeToBuffer();
    final res = await _send('POST', '/auth/chofer', body: body);
    _expect(res, '/auth/chofer');
    return Token.fromBuffer(res.body);
  }

  Future<Token> passengerToken() async {
    final res = await _send('POST', '/auth/pasajero', body: Uint8List(0));
    _expect(res, '/auth/pasajero');
    return Token.fromBuffer(res.body);
  }

  void close() => _http.close(force: true);

  void _expect(_Response res, String path) {
    if (res.status != HttpStatus.ok) throw ApiException(res.status, path);
  }

  Future<_Response> _send(String method, String path,
      {Map<String, String>? query, Uint8List? body, String? etag}) async {
    final uri = baseUri.replace(path: '${baseUri.path}$path'.replaceAll('//', '/'), queryParameters: query);
    final req = await _http.openUrl(method, uri).timeout(timeout);
    req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    req.headers.set(HttpHeaders.acceptHeader, 'application/x-protobuf');
    if (etag != null) req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    if (body != null) {
      req.headers.contentType = ContentType('application', 'x-protobuf');
      req.contentLength = body.length;
      req.add(body);
    }
    usage.httpTx += _requestHeaderBytes(method, uri, req.headers) + (body?.length ?? 0);

    final res = await req.close().timeout(timeout);
    final raw = await _readAll(res).timeout(timeout);
    var headerBytes = 17; // "HTTP/1.1 200 OK\r\n"
    res.headers.forEach((name, values) {
      for (final v in values) {
        headerBytes += name.length + v.length + 4;
      }
    });
    usage.httpRx += headerBytes + 2 + raw.length;

    final gzipped = res.headers.value(HttpHeaders.contentEncodingHeader)?.toLowerCase() == 'gzip';
    return _Response(res.statusCode, gzipped ? Uint8List.fromList(gzip.decode(raw)) : raw,
        res.headers.value(HttpHeaders.etagHeader));
  }

  static int _requestHeaderBytes(String method, Uri uri, HttpHeaders headers) {
    var n = method.length + uri.path.length + uri.query.length + 12 + uri.host.length + 8;
    headers.forEach((name, values) {
      for (final v in values) {
        n += name.length + v.length + 4;
      }
    });
    return n;
  }

  static Future<Uint8List> _readAll(Stream<List<int>> s) async {
    final b = BytesBuilder(copy: false);
    await for (final chunk in s) {
      b.add(chunk);
    }
    return b.takeBytes();
  }
}

class _Response {
  _Response(this.status, this.body, this.etag);

  final int status;
  final Uint8List body;
  final String? etag;
}
