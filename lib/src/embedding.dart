import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class EmbeddingRecord {
  EmbeddingRecord(this.id, this.vector);
  final String id;
  final List<double> vector;

  Map<String, dynamic> toJson() => {'id': id, 'vector': vector};

  static EmbeddingRecord fromJson(Map<String, dynamic> json) =>
      EmbeddingRecord(json['id'] as String, (json['vector'] as List).cast<num>().map((e) => e.toDouble()).toList());
}

class EmbeddingPak {
  EmbeddingPak({required this.model, required this.dimension, required this.records});

  final String model;
  final int dimension;
  final List<EmbeddingRecord> records;

  Uint8List toPakBytes() {
    final payload = utf8.encode(jsonEncode({
      'model': model,
      'dimension': dimension,
      'records': records.map((e) => e.toJson()).toList(),
    }));
    final length = payload.length;
    final bytes = BytesBuilder();
    bytes.add([0x53, 0x43, 0x4F, 0x4D]); // SCOM
    final lenData = ByteData(4)..setUint32(0, length, Endian.little);
    bytes.add(lenData.buffer.asUint8List());
    bytes.add(payload);
    return bytes.toBytes();
  }

  static EmbeddingPak fromPakBytes(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic != 'SCOM') throw StateError('Invalid pak header');
    final length = bd.getUint32(4, Endian.little);
    final payload = utf8.decode(bytes.sublist(8, 8 + length));
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return EmbeddingPak(
      model: json['model'] as String,
      dimension: json['dimension'] as int,
      records: (json['records'] as List)
          .map((e) => EmbeddingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EmbeddingService {
  EmbeddingService({this.dimension = 64, this.model = 'hash-embedding-v1'});

  final int dimension;
  final String model;

  List<double> embed(String text) {
    final digest = sha256.convert(utf8.encode(text)).bytes;
    final vector = List<double>.filled(dimension, 0);
    for (var i = 0; i < dimension; i++) {
      final b = digest[i % digest.length];
      vector[i] = (b / 255.0) * (i.isEven ? 1 : -1);
    }
    final norm = sqrt(vector.fold<double>(0, (p, v) => p + v * v));
    return vector.map((e) => norm == 0 ? 0.0 : e / norm).toList();
  }

  double cosine(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < min(a.length, b.length); i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
