import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorColors {
  static const Map<String, String> labels = {
    'background': 'پس‌زمینه برنامه',
    'display': 'پس‌زمینه نمایشگر',
    'number': 'پس‌زمینه دکمه‌های عددی',
    'utility': 'پس‌زمینه دکمه‌های جانبی',
    'operator': 'پس‌زمینه دکمه‌های عملیاتی',
    'buttonText': 'رنگ متن دکمه‌ها',
    'displayText': 'رنگ عدد نمایشگر',
    'expressionText': 'رنگ عبارت محاسبه',
    'appBar': 'پس‌زمینه نوار بالا',
    'accent': 'رنگ تأکیدی و آیکون‌ها',
  };

  static const Map<String, int> defaults = {
    'background': 0xFF050607,
    'display': 0xFF090B0D,
    'number': 0xFFD4D5D5,
    'utility': 0xFFFFFFFF,
    'operator': 0xFFFF9800,
    'buttonText': 0xFF000000,
    'displayText': 0xFFF2F2F2,
    'expressionText': 0xFF858B91,
    'appBar': 0xFF050607,
    'accent': 0xFFFF9800,
  };

  static final Map<String, int> values = Map.from(defaults);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in defaults.keys) {
      values[key] = prefs.getInt('calculator_color_$key') ?? defaults[key]!;
    }
  }

  static Color get(String key) => Color(values[key] ?? 0xFF000000);

  static Future<void> set(String key, int color) async {
    values[key] = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calculator_color_$key', color);
  }

  static Future<void> reset() async {
    values
      ..clear()
      ..addAll(defaults);

    final prefs = await SharedPreferences.getInstance();
    for (final key in defaults.keys) {
      await prefs.remove('calculator_color_$key');
    }
  }
}

class ColorSettingsPage extends StatefulWidget {
  const ColorSettingsPage({super.key});

  @override
  State<ColorSettingsPage> createState() => _ColorSettingsPageState();
}

class _ColorSettingsPageState extends State<ColorSettingsPage> {
  final List<int> palette = const [
    0xFF050607,
    0xFF090B0D,
    0xFF15191D,
    0xFF292D31,
    0xFF424A52,
    0xFF8A9198,
    0xFFD4D5D5,
    0xFFFFFFFF,
    0xFFFF9800,
    0xFFFF5722,
    0xFFF44336,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF673AB7,
    0xFF3F51B5,
    0xFF2196F3,
    0xFF03A9F4,
    0xFF009688,
    0xFF4CAF50,
    0xFF8BC34A,
    0xFFFFEB3B,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات رنگ‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'برای تغییر رنگ هر بخش، رنگ فعلی آن را انتخاب کنید.',
          ),
          const SizedBox(height: 12),
          ...CalculatorColors.labels.entries.map((entry) {
            final color = CalculatorColors.get(entry.key);
            return Card(
              child: ListTile(
                title: Text(entry.value),
                trailing: InkWell(
                  onTap: () => _chooseColor(entry.key, entry.value),
                  child: Container(
                    width: 42,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                onTap: () => _chooseColor(entry.key, entry.value),
              ),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await CalculatorColors.reset();
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('رنگ‌ها به حالت اولیه برگشتند')),
              );
            },
            child: const Text('بازگردانی رنگ‌های پیش‌فرض'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseColor(String key, String title) async {
    int selected = CalculatorColors.values[key] ?? 0xFFFFFFFF;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: palette.map((value) {
                final isSelected = value == selected;
                return InkWell(
                  onTap: () => setDialogState(() => selected = value),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(value),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('ذخیره رنگ'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    await CalculatorColors.set(key, result);
    if (!mounted) return;
    setState(() {});
  }
}
