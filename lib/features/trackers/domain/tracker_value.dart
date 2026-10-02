import 'package:habito/core/database/enums.dart';

sealed class TrackerValue {
  const TrackerValue();

  TrackerType get type;
  
  // Serialization representations for Drift logs
  double? get asNumber => null;
  String? get asText => null;
}

class BooleanValue extends TrackerValue {
  final bool value;
  const BooleanValue(this.value);
  @override TrackerType get type => TrackerType.boolean;
  @override double? get asNumber => value ? 1.0 : 0.0;
}

class IntegerValue extends TrackerValue {
  final int value;
  const IntegerValue(this.value);
  @override TrackerType get type => TrackerType.integer;
  @override double? get asNumber => value.toDouble();
}

class DecimalValue extends TrackerValue {
  final double value;
  const DecimalValue(this.value);
  @override TrackerType get type => TrackerType.decimal;
  @override double? get asNumber => value;
}

class DurationValue extends TrackerValue {
  final Duration value;
  const DurationValue(this.value);
  @override TrackerType get type => TrackerType.duration;
  @override double? get asNumber => value.inSeconds.toDouble();
}

class TextValue extends TrackerValue {
  final String value;
  const TextValue(this.value);
  @override TrackerType get type => TrackerType.text;
  @override String? get asText => value;
}

class RatingValue extends TrackerValue {
  final int value;
  const RatingValue(this.value);
  @override TrackerType get type => TrackerType.rating;
  @override double? get asNumber => value.toDouble();
}

class SelectionValue extends TrackerValue {
  final String value;
  const SelectionValue(this.value);
  @override TrackerType get type => TrackerType.selection;
  @override String? get asText => value;
}

class TimeValue extends TrackerValue {
  // Stored as HH:MM format
  final String time;
  const TimeValue(this.time);
  @override TrackerType get type => TrackerType.timestamp;
  @override String? get asText => time;
}

class TrackerValueConverter {
  static TrackerValue? fromDatabase(TrackerType type, double? numVal, String? textVal) {
    switch (type) {
      case TrackerType.boolean:
        if (numVal == null) return null;
        return BooleanValue(numVal > 0);
      case TrackerType.integer:
        if (numVal == null) return null;
        return IntegerValue(numVal.toInt());
      case TrackerType.decimal:
        if (numVal == null) return null;
        return DecimalValue(numVal);
      case TrackerType.duration:
        if (numVal == null) return null;
        return DurationValue(Duration(seconds: numVal.toInt()));
      case TrackerType.text:
        if (textVal == null) return null;
        return TextValue(textVal);
      case TrackerType.rating:
        if (numVal == null) return null;
        return RatingValue(numVal.toInt());
      case TrackerType.selection:
        if (textVal == null) return null;
        return SelectionValue(textVal);
      case TrackerType.timestamp:
        if (textVal == null) return null;
        return TimeValue(textVal);
    }
  }
}
