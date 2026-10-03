/// Interprets both legacy academic IDs (`III-AIDS-B`) and stable cohort IDs
/// (`24-AIDS-B`) while the department migrates to cohort-based sections.
class SectionIdentity {
  final int year;
  final String section;
  final int? cohortYear;

  const SectionIdentity({
    required this.year,
    required this.section,
    this.cohortYear,
  });

  static SectionIdentity parse(String sectionId) {
    final parts = sectionId.trim().toUpperCase().split('-');
    final prefix = parts.isNotEmpty ? parts.first : '';
    final section = parts.length >= 3 && parts[2].isNotEmpty
        ? parts[2]
        : 'A';

    const romanYears = {'I': 1, 'II': 2, 'III': 3, 'IV': 4};
    final legacyYear = romanYears[prefix];
    if (legacyYear != null) {
      return SectionIdentity(year: legacyYear, section: section);
    }

    final rawCohort = int.tryParse(prefix);
    if (rawCohort != null) {
      final cohortYear = rawCohort < 100 ? 2000 + rawCohort : rawCohort;
      final now = DateTime.now();
      final academicEndYear = now.month >= 6 ? now.year + 1 : now.year;
      final calculatedYear = academicEndYear - cohortYear;
      return SectionIdentity(
        year: calculatedYear < 1
            ? 1
            : calculatedYear > 4
            ? 4
            : calculatedYear,
        section: section,
        cohortYear: cohortYear,
      );
    }

    return const SectionIdentity(year: 1, section: 'A');
  }

  String get displayLabel {
    const roman = ['I', 'II', 'III', 'IV'];
    return '${roman[year - 1]}-AIDS-$section';
  }
}
