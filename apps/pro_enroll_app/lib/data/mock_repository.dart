import 'dart:async';
import 'dart:math';

import 'models.dart';

/// A purely in-memory mock backend for the Pro-Enroll app scaffold.
///
/// In production this would be replaced by a real `ApiClient` that talks
/// to the backend described in `docs/06-api-specification.md`.
class MockRepository {
  MockRepository();

  final _rand = Random();

  // ── Auth ────────────────────────────────────────────────────────────
  Future<String> sendOtp(String phone) async {
    await _delay();
    return 'req_${_rand.nextInt(1 << 32)}';
  }

  Future<bool> verifyOtp({required String requestId, required String otp}) async {
    await _delay();
    // Demo: any 6-digit OTP works; '000000' fails to show error UX.
    if (otp.length != 6 || otp == '000000') return false;
    return true;
  }

  // ── KYC ────────────────────────────────────────────────────────────
  Future<String> initiateAadhaar(String last4) async {
    await _delay();
    return 'kyc_${_rand.nextInt(1 << 32)}';
  }

  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp}) async {
    await _delay();
    return otp.length >= 4 && otp != '0000';
  }

  Future<double> uploadSelfie() async {
    await _delay(seconds: 2);
    // Mock face-match score.
    return 0.85 + _rand.nextDouble() * 0.15;
  }

  // ── Jobs ──────────────────────────────────────────────────────────
  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes) async {
    await _delay();
    if (categoryCodes.isEmpty) return const [];
    return _demoOffers(categoryCodes);
  }

  Future<EarningsSummary> fetchEarnings() async {
    await _delay();
    return EarningsSummary(
      todayPaise: 65000,
      weekPaise: 420000,
      monthPaise: 1850000,
      payoutsThisMonthPaise: 1620000,
      pendingPayoutPaise: 23000,
      jobsToday: 3,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Future<void> _delay({int seconds = 1}) =>
      Future<void>.delayed(Duration(milliseconds: 400 * seconds));

  List<JobOffer> _demoOffers(List<String> categories) {
    final now = DateTime.now();
    final pool = <Map<String, Object>>[
      {
        'cat': 'ac',
        'problem': 'AC not cooling — bedroom split AC, 1.5T',
        'customer': 'Saraswathi',
        'area': 'Mission Street, Pondicherry',
        'distance': 1.2,
        'fee': 20000,
      },
      {
        'cat': 'plumber',
        'problem': 'Kitchen tap is leaking continuously',
        'customer': 'Anjali',
        'area': 'Lawspet, Pondicherry',
        'distance': 2.8,
        'fee': 15000,
      },
      {
        'cat': 'ro',
        'problem': 'RO not producing water — filter change needed',
        'customer': 'Murugan R.',
        'area': 'Bharathiar Road, Karaikal',
        'distance': 0.9,
        'fee': 15000,
      },
      {
        'cat': 'fridge',
        'problem': 'Fridge not cooling, water dripping inside',
        'customer': 'Selvi',
        'area': 'Reddiarpalayam, Pondicherry',
        'distance': 3.5,
        'fee': 20000,
      },
      {
        'cat': 'bike',
        'problem': 'Bike not starting — TVS Apache 160',
        'customer': 'Ravi',
        'area': 'Mudaliarpet, Pondicherry',
        'distance': 1.7,
        'fee': 15000,
      },
      {
        'cat': 'wash',
        'problem': 'Washing machine drum not spinning',
        'customer': 'Lakshmi',
        'area': 'Villianur, Pondicherry',
        'distance': 4.1,
        'fee': 20000,
      },
    ];

    final filtered = pool.where((e) => categories.contains(e['cat']));
    return [
      for (final (i, m) in filtered.indexed)
        JobOffer(
          id: 'off_${i + 1}',
          code: 'PE-2026-${(900 + i).toString().padLeft(6, '0')}',
          categoryCode: m['cat'] as String,
          problem: m['problem'] as String,
          customerName: m['customer'] as String,
          customerAreaName: m['area'] as String,
          distanceKm: m['distance'] as double,
          visitFeePaise: m['fee'] as int,
          preferredTime: now.add(Duration(hours: 1 + i)),
          expiresAt: now.add(const Duration(seconds: 60)),
        ),
    ];
  }
}
