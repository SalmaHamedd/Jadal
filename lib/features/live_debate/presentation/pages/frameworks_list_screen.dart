import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/hex_color.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';

/// Read-only list of every motion framework defined in the system (§9 drawer
/// entry) — reuses the same `/motion-frameworks` endpoint the debate search
/// filter dialog (§8) already fetches, rather than a second lookup.
class FrameworksListScreen extends StatefulWidget {
  const FrameworksListScreen({super.key});

  @override
  State<FrameworksListScreen> createState() => _FrameworksListScreenState();
}

class _FrameworksListScreenState extends State<FrameworksListScreen> {
  bool _loading = true;
  String? _error;
  List<({int id, String name, String? colorHex})> _frameworks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await di.sl<LiveDebateRepository>().getMotionFrameworks();
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (list) => setState(() {
        _frameworks = [for (final f in list) (id: f.id, name: f.name, colorHex: f.colorHex)];
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Frameworks', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(fontFamily: 'Cairo')))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _frameworks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final f = _frameworks[i];
                      final color = colorFromHex(f.colorHex) ?? JadalColors.primaryBlue;
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: color, radius: 8),
                        title: Text(f.name, style: const TextStyle(fontFamily: 'Cairo')),
                      );
                    },
                  ),
      ),
    );
  }
}
