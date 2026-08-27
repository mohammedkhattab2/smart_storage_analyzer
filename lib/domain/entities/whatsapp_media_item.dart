import 'package:equatable/equatable.dart';

/// Enum representing WhatsApp media categories
enum WhatsAppMediaType {
  voiceNotes,
  sentMedia,
  statuses,
  images,
  videos,
  audio,
  documents,
  stickers,
  animatedGifs,
}

/// Entity representing a single WhatsApp media file
class WhatsAppMediaItem extends Equatable {
  final String id;
  final String name;
  final String path;
  final String uri;
  final int sizeBytes;
  final DateTime dateModified;
  final String extension;
  final String mimeType;
  final WhatsAppMediaType category;
  final bool isSent;
  final bool isVoiceNote;

  const WhatsAppMediaItem({
    required this.id,
    required this.name,
    required this.path,
    required this.uri,
    required this.sizeBytes,
    required this.dateModified,
    required this.extension,
    required this.mimeType,
    required this.category,
    required this.isSent,
    required this.isVoiceNote,
  });

  /// Check if file is older than specified days
  bool isOlderThan(int days) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return dateModified.isBefore(threshold);
  }

  /// Whether this item is safely recommended for quick clean (Sent media, Statuses, Old Voice Notes)
  bool get isQuickCleanRecommended {
    if (category == WhatsAppMediaType.statuses) return true;
    if (isSent) return true;
    if (isVoiceNote && isOlderThan(30)) return true;
    return false;
  }

  factory WhatsAppMediaItem.fromMap(Map<dynamic, dynamic> map) {
    final catStr = map['category'] as String? ?? 'documents';
    final isSent = map['isSent'] as bool? ?? false;
    final isVoiceNote = map['isVoiceNote'] as bool? ?? false;

    WhatsAppMediaType cat;
    if (isSent && catStr != 'voiceNotes') {
      cat = WhatsAppMediaType.sentMedia;
    } else {
      switch (catStr) {
        case 'images':
          cat = WhatsAppMediaType.images;
          break;
        case 'videos':
          cat = WhatsAppMediaType.videos;
          break;
        case 'voiceNotes':
          cat = WhatsAppMediaType.voiceNotes;
          break;
        case 'audio':
          cat = WhatsAppMediaType.audio;
          break;
        case 'statuses':
          cat = WhatsAppMediaType.statuses;
          break;
        case 'stickers':
          cat = WhatsAppMediaType.stickers;
          break;
        case 'animatedGifs':
          cat = WhatsAppMediaType.animatedGifs;
          break;
        case 'documents':
        default:
          cat = WhatsAppMediaType.documents;
          break;
      }
    }

    return WhatsAppMediaItem(
      id: map['id']?.toString() ?? map['uri']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      uri: map['uri']?.toString() ?? '',
      sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
      dateModified: DateTime.fromMillisecondsSinceEpoch(
        (map['lastModified'] as num?)?.toInt() ?? 0,
      ),
      extension: map['extension']?.toString() ?? '',
      mimeType: map['mimeType']?.toString() ?? 'application/octet-stream',
      category: cat,
      isSent: isSent,
      isVoiceNote: isVoiceNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        uri,
        sizeBytes,
        dateModified,
        extension,
        mimeType,
        category,
        isSent,
        isVoiceNote,
      ];
}
