import 'package:flutter/material.dart';

class EventEntity {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final int colorValue;

  const EventEntity({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.colorValue,
  });

  Color get color => Color(colorValue);
}
