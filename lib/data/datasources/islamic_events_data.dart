import '../../domain/entities/islamic_event_entity.dart';

class IslamicEventsData {
  static const List<IslamicEventEntity> allEvents = [
    IslamicEventEntity(
      name: 'Islamic New Year',
      description: 'The first day of the Hijri year (1st Muharram).',
      hijriMonth: 1,
      hijriDay: 1,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Ashura',
      description: 'A day of fasting and reflection (10th Muharram).',
      hijriMonth: 1,
      hijriDay: 10,
    ),
    IslamicEventEntity(
      name: 'Mawlid al-Nabi',
      description: 'The birthday of Prophet Muhammad (PBUH) (12th Rabi al-Awwal).',
      hijriMonth: 3,
      hijriDay: 12,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Isra and Mi\'raj',
      description: 'The Night Journey and Ascension of the Prophet (27th Rajab).',
      hijriMonth: 7,
      hijriDay: 27,
    ),
    IslamicEventEntity(
      name: 'Mid-Sha\'ban',
      description: 'The night of forgiveness (15th Sha\'ban).',
      hijriMonth: 8,
      hijriDay: 15,
    ),
    IslamicEventEntity(
      name: 'Start of Ramadan',
      description: 'The first day of fasting (1st Ramadan).',
      hijriMonth: 9,
      hijriDay: 1,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Laylat al-Qadr',
      description: 'The Night of Power (approx. 27th Ramadan).',
      hijriMonth: 9,
      hijriDay: 27,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Eid al-Fitr',
      description: 'Festival of breaking the fast (1st Shawwal).',
      hijriMonth: 10,
      hijriDay: 1,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Day of Arafah',
      description: 'The pinnacle of Hajj (9th Dhul-Hijjah).',
      hijriMonth: 12,
      hijriDay: 9,
      isMajor: true,
    ),
    IslamicEventEntity(
      name: 'Eid al-Adha',
      description: 'Festival of Sacrifice (10th Dhul-Hijjah).',
      hijriMonth: 12,
      hijriDay: 10,
      isMajor: true,
    ),
  ];
}
