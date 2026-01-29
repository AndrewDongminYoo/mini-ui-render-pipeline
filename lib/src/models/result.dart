/// Result model representing the state after processing an event.
class EventResult {
  /// Index of the event that was processed (0-based).
  final int afterEvent;

  /// List of node IDs that need structure recomputation.
  final List<String> recomputeStructure;

  /// List of node IDs that need layout recomputation.
  final List<String> recomputeLayout;

  /// Paint order (pre-order DFS traversal).
  final List<String> paintOrder;

  EventResult({
    required this.afterEvent,
    required this.recomputeStructure,
    required this.recomputeLayout,
    required this.paintOrder,
  });

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'afterEvent': afterEvent,
      'recomputeStructure': recomputeStructure,
      'recomputeLayout': recomputeLayout,
      'paintOrder': paintOrder,
    };
  }

  /// Create from JSON.
  factory EventResult.fromJson(Map<String, dynamic> json) {
    return EventResult(
      afterEvent: json['afterEvent'] as int,
      recomputeStructure: List<String>.from(json['recomputeStructure'] as List),
      recomputeLayout: List<String>.from(json['recomputeLayout'] as List),
      paintOrder: List<String>.from(json['paintOrder'] as List),
    );
  }

  @override
  String toString() {
    return 'EventResult('
        'afterEvent: $afterEvent, '
        'structure: ${recomputeStructure.length}, '
        'layout: ${recomputeLayout.length}, '
        'paint: ${paintOrder.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventResult &&
          runtimeType == other.runtimeType &&
          afterEvent == other.afterEvent &&
          _listEquals(recomputeStructure, other.recomputeStructure) &&
          _listEquals(recomputeLayout, other.recomputeLayout) &&
          _listEquals(paintOrder, other.paintOrder);

  @override
  int get hashCode =>
      afterEvent.hashCode ^ recomputeStructure.hashCode ^ recomputeLayout.hashCode ^ paintOrder.hashCode;

  /// Helper to compare lists.
  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
