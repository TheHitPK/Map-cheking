import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;

/// /lineas body + ETag in drift: the next start revalidates with a 304 (or works offline).
class LinesCache {
  LinesCache(this.db, this.api);

  final AppDb db;
  final ApiClient api;

  /// Cached lines (seeding the API client's ETag), or empty.
  Future<List<pb.Line>> cached() async {
    final body = await db.getBytes('lines');
    final etag = await db.getString('lines_etag');
    if (body == null || etag == null) return const [];
    final lines = pb.Lines.fromBuffer(body).lines;
    api.restoreLines(lines, etag);
    return lines;
  }

  /// Revalidates against the backend and stores a changed list.
  Future<List<pb.Line>> refresh() async {
    final before = api.linesEtag;
    final lines = await api.lines();
    final etag = api.linesEtag;
    if (etag != null && etag != before) {
      await db.putBytes('lines', pb.Lines(lines: lines).writeToBuffer());
      await db.putString('lines_etag', etag);
    }
    return lines;
  }
}
