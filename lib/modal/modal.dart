
const String tableNotes = 'docs';

class PDFFields {
  static final List<String> value = [id, title, location, timeCreated];

  static const String id = '_id';
  static const String title = 'title';
  static const String location = 'location';
  static const String timeCreated = 'time_created';
}

class PDFItems {
  final int? id;
  final String? title;
  final String? location;
  final DateTime? timeCreated;

  const PDFItems({
    this.id,
    required this.title,
    required this.location,
    required this.timeCreated
});

  static PDFItems fromJson(Map<String,Object?> json) => PDFItems(
      id: json[PDFFields.id] as int,
      title: json[PDFFields.title] as String,
      location: json[PDFFields.location] as String,
      timeCreated: DateTime.parse(json[PDFFields.timeCreated] as String)
  );

  Map<String, Object?> toJson() => {
    PDFFields.id: id,
    PDFFields.title: title,
    PDFFields.location: location,
    PDFFields.timeCreated: timeCreated!.toIso8601String()
  };
}