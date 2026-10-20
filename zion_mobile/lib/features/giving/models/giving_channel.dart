import 'package:flutter/material.dart';

class GivingChannel {
  final String id;
  final String name;
  final String provider;
  final String payNumber;
  final String accountName;
  final String ussdCode;
  final Color brandColor;
  final IconData icon;

  const GivingChannel({
    required this.id,
    required this.name,
    required this.provider,
    required this.payNumber,
    required this.accountName,
    required this.ussdCode,
    required this.brandColor,
    required this.icon,
  });
}

class GivingRecord {
  final String id;
  final String category; // Sadaka ya Jumapili, Zaka (Fungu la Kumi), Ujenzi wa Hekalu
  final double amount;
  final String paymentChannel;
  final String? referenceNumber;
  final DateTime date;

  GivingRecord({
    required this.id,
    required this.category,
    required this.amount,
    required this.paymentChannel,
    this.referenceNumber,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'paymentChannel': paymentChannel,
    'referenceNumber': referenceNumber,
    'date': date.toIso8601String(),
  };

  factory GivingRecord.fromJson(Map<String, dynamic> json) => GivingRecord(
    id: json['id'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    paymentChannel: json['paymentChannel'] as String,
    referenceNumber: json['referenceNumber'] as String?,
    date: DateTime.parse(json['date'] as String),
  );
}
