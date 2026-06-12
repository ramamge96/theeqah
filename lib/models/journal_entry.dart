class JournalEntryLine {
  final int? id;
  final int? journalEntryId;
  final String accountCode;
  final double debit;
  final double credit;
  final String? description;

  JournalEntryLine({
    this.id,
    this.journalEntryId,
    required this.accountCode,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });

  Map<String, dynamic> toMap({int? entryId}) {
    return {
      if (id != null) 'id': id,
      'journal_entry_id': entryId ?? journalEntryId,
      'account_code': accountCode,
      'debit': debit,
      'credit': credit,
      'description': description,
    };
  }

  factory JournalEntryLine.fromMap(Map<String, dynamic> map) {
    return JournalEntryLine(
      id: map['id'] as int?,
      journalEntryId: map['journal_entry_id'] as int?,
      accountCode: map['account_code'] ?? '',
      debit: (map['debit'] as num? ?? 0.0).toDouble(),
      credit: (map['credit'] as num? ?? 0.0).toDouble(),
      description: map['description'] as String?,
    );
  }
}

class JournalEntry {
  final int? id;
  final String entryDate;
  final String description;
  final String? sourceDocument;
  final String? referenceNo;
  final String createdAt;
  final int? costCenterId;
  final List<JournalEntryLine> lines;

  JournalEntry({
    this.id,
    required this.entryDate,
    required this.description,
    this.sourceDocument,
    this.referenceNo,
    required this.createdAt,
    this.costCenterId,
    this.lines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entry_date': entryDate,
      'description': description,
      'source_document': sourceDocument,
      'reference_no': referenceNo,
      'created_at': createdAt,
      'cost_center_id': costCenterId,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map, {List<JournalEntryLine> lines = const []}) {
    return JournalEntry(
      id: map['id'] as int?,
      entryDate: map['entry_date'] ?? '',
      description: map['description'] ?? '',
      sourceDocument: map['source_document'] as String?,
      referenceNo: map['reference_no'] as String?,
      createdAt: map['created_at'] ?? '',
      costCenterId: map['cost_center_id'] as int?,
      lines: lines,
    );
  }
}
