import 'package:url_launcher/url_launcher_string.dart';

import '../../domain/entities/store_entity.dart';

Future<bool> callStorePhone(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (normalized.isEmpty) return false;
  final url = 'tel:$normalized';
  if (!await canLaunchUrlString(url)) return false;
  return launchUrlString(url);
}

Future<bool> openStoreDirections(StoreEntity store) async {
  if (store.latitude == 0 && store.longitude == 0) return false;
  final url =
      'https://www.google.com/maps/dir/?api=1&destination=${store.latitude},${store.longitude}';
  if (!await canLaunchUrlString(url)) return false;
  return launchUrlString(url, mode: LaunchMode.externalApplication);
}

String formatStoreDistance(double? distanceKm, String kmLabel) {
  if (distanceKm == null) return '—';
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m';
  }
  return '${distanceKm.toStringAsFixed(1)} $kmLabel';
}
