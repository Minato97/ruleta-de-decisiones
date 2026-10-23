import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads.dart';
import 'logic.dart';
import 'wheel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdService.instance.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8B5CF6);
    return MaterialApp(
      title: 'Ruleta de Decisiones',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final List<SpinRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final lines = p.getStringList('history') ?? [];
    setState(
      () => _history
        ..clear()
        ..addAll(lines.map(SpinRecord.parse).whereType<SpinRecord>()),
    );
  }

  Future<void> _add(SpinRecord r) async {
    _history.insert(0, r);
    if (_history.length > 100) _history.removeRange(100, _history.length);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList('history', [for (final h in _history) h.toLine()]);
  }

  Future<void> _clear() async {
    setState(_history.clear);
    final p = await SharedPreferences.getInstance();
    await p.remove('history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tab == 0 ? 'Ruleta' : 'Historial')),
      body: IndexedStack(
        index: _tab,
        children: [
          WheelPage(onResult: _add),
          HistoryPage(history: _history, onClear: _clear),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.casino), label: 'Ruleta'),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Historial',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WheelPage extends StatefulWidget {
  const WheelPage({super.key, required this.onResult});

  final ValueChanged<SpinRecord> onResult;

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late final AnimationController _ctl;
  Animation<double>? _anim;
  double _rotation = 0;
  int _presetIndex = 0;
  late List<String> _options;
  final _input = TextEditingController();
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _options = List.of(presets[0].options);
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    _input.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _options.length < 2) return;
    final n = _options.length;
    final winner = _rng.nextInt(n);
    final target = restAngle(
      index: winner,
      count: n,
      jitter: _rng.nextDouble() * 2 - 1,
      turns: 5 + _rng.nextInt(3),
    );
    // Siempre avanza en sentido horario respecto al ángulo actual
    final from = _rotation;
    var end = target;
    while (end < from + 4 * pi) {
      end += 2 * pi;
    }
    _anim = Tween<double>(begin: from, end: end).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _rotation = _anim!.value));
    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();
    _ctl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      final idx = sectorAt(_rotation, n);
      setState(() => _spinning = false);
      HapticFeedback.heavyImpact();
      widget.onResult(
        SpinRecord(DateTime.now(), _options[idx], presets[_presetIndex].name),
      );
      AdService.instance.maybeShowInterstitial(every: 4);
      _showResult(_options[idx]);
    });
  }

  void _showResult(String text) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events,
          size: 40,
          color: Color(0xFFF59E0B),
        ),
        title: const Text('Resultado', textAlign: TextAlign.center),
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _spin();
            },
            child: const Text('Girar otra vez'),
          ),
        ],
      ),
    );
  }

  void _usePreset(int i) {
    if (_spinning) return;
    setState(() {
      _presetIndex = i;
      _options = List.of(presets[i].options);
    });
  }

  void _add() {
    final t = _input.text.trim();
    if (t.isEmpty || _options.length >= 16 || _spinning) return;
    setState(() => _options.add(t));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < presets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(presets[i].icon, size: 18),
                    label: Text(presets[i].name),
                    selected: _presetIndex == i,
                    onSelected: (_) => _usePreset(i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 320,
            height: 340,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: CustomPaint(
                      painter: WheelPainter(
                        _options,
                        _rotation,
                        theme.colorScheme.onSurface,
                        DefaultTextStyle.of(context).style.fontFamily,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 40,
                    child: CustomPaint(painter: PointerPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _options.length < 2 || _spinning ? null : _spin,
            icon: const Icon(Icons.casino),
            label: Text(
              _spinning ? 'Girando…' : 'GIRAR',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opciones (${_options.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _options.length; i++)
                    InputChip(
                      avatar: CircleAvatar(
                        backgroundColor: wheelColors[i % wheelColors.length],
                        radius: 8,
                      ),
                      label: Text(_options[i]),
                      onDeleted: _options.length > 2 && !_spinning
                          ? () => setState(() => _options.removeAt(i))
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _add(),
                      decoration: InputDecoration(
                        hintText: 'Agregar opción',
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.history, required this.onClear});

  final List<SpinRecord> history;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay giros. Gira la ruleta y tus resultados aparecerán aquí.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final h in history)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.casino)),
            title: Text(
              h.result,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${h.wheel} · ${h.when.day}/${h.when.month} ${h.when.hour.toString().padLeft(2, '0')}:${h.when.minute.toString().padLeft(2, '0')}',
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar historial'),
        ),
      ],
    );
  }
}
