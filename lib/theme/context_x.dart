import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import '../services/progress.dart';
import 'palette.dart';

extension ContextX on BuildContext {
  /// Player progress/inventory (rebuilds the caller when it changes).
  Progress get progress => ProgressScope.of(this);

  /// The active colour palette.
  AppPalette get pal => progress.palette;

  /// Localised strings.
  S get s => S.of(this);
}
