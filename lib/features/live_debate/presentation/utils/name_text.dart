import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// The direction a person's name should be laid out in, taken from the name
/// itself rather than the surrounding layout.
///
/// The speakers row is forced left-to-right so the two sides never swap places
/// in Arabic. Without this, an Arabic name inside that row is measured as if it
/// were English: it aligns to the wrong edge and, once it is too long, the "…"
/// lands at the wrong end and hides the start of the name instead of its tail.
TextDirection directionOfName(String? name) =>
    Bidi.detectRtlDirectionality(name ?? '')
        ? TextDirection.rtl
        : TextDirection.ltr;
