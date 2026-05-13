import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/vehicle_profile.dart';

class VehicleSearchResult {
  final String id;
  final String make;
  final String model;
  final String? generation;
  final int? yearFrom;
  final int? yearTo;
  final String? trim;
  final VehicleProfile profile;

  const VehicleSearchResult({
    required this.id,
    required this.make,
    required this.model,
    this.generation,
    this.yearFrom,
    this.yearTo,
    this.trim,
    required this.profile,
  });

  String get displayName {
    final parts = [make, model, ?generation];
    return parts.join(' ');
  }

  String get yearRange {
    if (yearFrom == null) return '';
    return yearTo != null ? '$yearFrom–$yearTo' : '$yearFrom–atual';
  }

  factory VehicleSearchResult.fromJson(Map<String, dynamic> j) {
    final rawRatios = j['gear_ratios'] as List?;
    final ratios = rawRatios?.map((e) => (e as num).toDouble()).toList() ?? [];

    return VehicleSearchResult(
      id: j['id'] as String,
      make: j['make'] as String? ?? '',
      model: j['model'] as String? ?? '',
      generation: j['generation'] as String?,
      yearFrom: j['year_from'] as int?,
      yearTo: j['year_to'] as int?,
      trim: j['trim'] as String?,
      profile: VehicleProfile(
        engineCode: j['engine_code'] as String? ?? '',
        displacementCc: j['displacement_cc'] as int? ?? 0,
        powerHp: j['power_hp'] as int? ?? 0,
        powerRpm: j['power_rpm'] as int? ?? 6000,
        torqueNm: j['torque_nm'] as int? ?? 0,
        torqueRpm: j['torque_rpm'] as int? ?? 2000,
        turbocharged: j['turbocharged'] as bool? ?? false,
        compressionRatio:
            (j['compression_ratio'] as num?)?.toDouble() ?? 10.0,
        transmissionType:
            j['transmission_type'] as String? ?? 'Manual',
        gearCount: j['gear_count'] as int? ?? 6,
        gearRatios: ratios,
        finalDriveRatio:
            (j['final_drive_ratio'] as num?)?.toDouble() ?? 4.0,
        tireWidth: j['tire_width'] as int? ?? 205,
        tireAspect: j['tire_aspect'] as int? ?? 55,
        wheelDiameterIn: j['wheel_diameter_in'] as int? ?? 16,
        tankCapacityL: j['tank_capacity_l'] as int? ?? 50,
      ),
    );
  }
}

class VehicleSearchService {
  static const _table = 'vehicles_view';

  static Future<List<VehicleSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final response = await Supabase.instance.client
        .from(_table)
        .select()
        .or('make.ilike.%$q%,model.ilike.%$q%,generation.ilike.%$q%,trim.ilike.%$q%')
        .order('make')
        .order('model')
        .order('year_from', ascending: false)
        .limit(40);

    return (response as List)
        .map((row) =>
            VehicleSearchResult.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
