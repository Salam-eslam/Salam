import 'package:equatable/equatable.dart';

class IslamicEventEntity extends Equatable {
  final String name;
  final String description;
  final int hijriMonth;
  final int hijriDay;
  final bool isMajor; // For highlighting major events like Eid

  const IslamicEventEntity({
    required this.name,
    required this.description,
    required this.hijriMonth,
    required this.hijriDay,
    this.isMajor = false,
  });

  @override
  List<Object?> get props => [name, description, hijriMonth, hijriDay, isMajor];
}
