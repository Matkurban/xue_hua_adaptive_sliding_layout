import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/enums/size_preset.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';

class SizePresetScreen extends StatelessWidget {
  const SizePresetScreen({
    super.key,
    required this.child,
    required this.context,
  });

  final BuildContext context;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screenSize = MediaQuery.sizeOf(context);
    return Material(
      child: Scaffold(
        backgroundColor: theme.inputDecorationTheme.fillColor,
        body: SignalBuilder(
          builder: (context) {
            SizePreset sizePreset =
                AppSettingServices.instance.sizePreset.value;
            double screenWidth = sizePreset.width ?? screenSize.width;
            return Center(
              child: Container(
                width: screenWidth,
                height: double.infinity,
                margin: .all(12),
                clipBehavior: .hardEdge,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(size: Size(screenWidth, screenSize.height - 24)),
                  child: child,
                ),
              ),
            );
          },
        ),
        floatingActionButton: SignalBuilder(
          builder: (context) {
            return SegmentedButton<SizePreset>(
              segments: SizePreset.values.map((item) {
                return ButtonSegment<SizePreset>(
                  value: item,
                  label: Text(item.name),
                );
              }).toList(),
              selected: {AppSettingServices.instance.sizePreset.value},
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                AppSettingServices.instance.sizePreset.value = value.first;
              },
            );
          },
        ),
      ),
    );
  }
}
