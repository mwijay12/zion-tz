import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sayuni/core/constants/church_profile.dart';
import 'package:sayuni/core/theme/app_colors.dart';
import '../models/giving_channel.dart';

class GivingService {
  static const String _recordsKey = 'zion_giving_records';

  static const List<GivingChannel> channels = [
    GivingChannel(
      id: 'mpesa',
      name: 'Lipa kwa M-Pesa',
      provider: 'Vodacom M-Pesa',
      payNumber: ChurchProfile.mpesaLipaNumber,
      accountName: ChurchProfile.mpesaAccountName,
      ussdCode: ChurchProfile.mpesaUssd,
      brandColor: AppColors.mpesaGreen,
      icon: Icons.phone_android_rounded,
    ),
    GivingChannel(
      id: 'tigopesa',
      name: 'Lipa kwa TigoPesa',
      provider: 'Tigo Pesa',
      payNumber: ChurchProfile.tigopesaLipaNumber,
      accountName: ChurchProfile.tigopesaAccountName,
      ussdCode: ChurchProfile.tigopesaUssd,
      brandColor: AppColors.tigoBlue,
      icon: Icons.account_balance_wallet_rounded,
    ),
    GivingChannel(
      id: 'airtel',
      name: 'Lipa kwa Airtel Money',
      provider: 'Airtel Money',
      payNumber: ChurchProfile.airtelLipaNumber,
      accountName: ChurchProfile.airtelAccountName,
      ussdCode: ChurchProfile.airtelUssd,
      brandColor: AppColors.airtelRed,
      icon: Icons.contactless_rounded,
    ),
    GivingChannel(
      id: 'crdb',
      name: 'Benki ya CRDB',
      provider: 'CRDB Bank Plc',
      payNumber: ChurchProfile.crdbAccountNumber,
      accountName: ChurchProfile.crdbAccountName,
      ussdCode: '*150*03#',
      brandColor: AppColors.crdbGreen,
      icon: Icons.account_balance_rounded,
    ),
  ];

  // Church Building Project Parameters
  static const double buildingTarget = 120000000; // TSh 120,000,000
  static const double buildingRaised = 68450000;   // TSh 68,450,000
  static const String buildingProjectName = 'Ujenzi wa Hekalu — Awamu ya Pili (Kuezeka na Sakafu)';

  Future<List<GivingRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recordsKey);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.map((item) => GivingRecord.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> addRecord(GivingRecord record) async {
    final list = await getRecords();
    list.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, json.encode(list.map((r) => r.toJson()).toList()));
  }
}
