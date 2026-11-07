import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'formulas_page.dart';
import 'custom_buttons_page.dart';
import 'add_button_page.dart';
import 'color_settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CalculatorColors.load();
  runApp(const AdvancedCalculatorApp());
}

class SavedCalculation {
  final String name;
  final String expression;
  final String result;
  final DateTime dateTime;

  SavedCalculation({
    required this.name,
    required this.expression,
    required this.result,
    required this.dateTime,
  });
}

class AdvancedCalculatorApp extends StatelessWidget {
  const AdvancedCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ماشین‌حساب پیشرفته',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CalculatorColors.get('background'),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: CalculatorColors.get('appBar'),
          foregroundColor: Colors.white,
        ),
      ),
      routes: {
        '/add-button': (_) => const AddButtonPage(),
        '/formulas': (_) => const FormulasPage(),
        '/colors': (_) => const ColorSettingsPage(),
      },
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  String expression = '';

  double? firstNumber;
  String? operation;
  bool startNewNumber = true;

  int decimalPlaces = 2;
  int historyIndex = -1;

  final List<SavedCalculation> history = [];
  final List<SavedCalculation> saved = [];

  Map<String, String> slots = {
    'x': '',
    'y': '',
    'z': '',
  };

  Map<String, String> slotNames = {
    'x': 'x',
    'y': 'y',
    'z': 'z',
  };

  // ==========================================
  // تنظیمات اندازه نمایشگر و دکمه‌ها
  // ==========================================

  double displayHeightFactor = 0.27;
  double resultFontSize = 42;
  double buttonSpacing = 2;
  double buttonFontSize = 22;

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadDisplaySettings();
  }

  // ==========================================
  // بارگذاری تنظیمات اندازه از حافظه
  // ==========================================

  Future<void> _loadDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      displayHeightFactor = prefs.getDouble('displayHeightFactor') ?? 0.27;

      resultFontSize = prefs.getDouble('resultFontSize') ?? 42;

      buttonSpacing = prefs.getDouble('buttonSpacing') ?? 2;

      buttonFontSize = prefs.getDouble('buttonFontSize') ?? 22;
    });
  }

  // ==========================================
  // ذخیره تنظیمات اندازه در حافظه
  // ==========================================

  Future<void> _saveDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      'displayHeightFactor',
      displayHeightFactor,
    );

    await prefs.setDouble(
      'resultFontSize',
      resultFontSize,
    );

    await prefs.setDouble(
      'buttonSpacing',
      buttonSpacing,
    );

    await prefs.setDouble(
      'buttonFontSize',
      buttonFontSize,
    );
  }

  // ==========================================
  // صفحه تنظیمات اندازه نمایشگر و دکمه‌ها
  // ==========================================

  Future<void> openLayoutSettings() async {
    double tempDisplayHeight = displayHeightFactor;
    double tempResultFontSize = resultFontSize;
    double tempButtonSpacing = buttonSpacing;
    double tempButtonFontSize = buttonFontSize;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget buildSlider({
              required String title,
              required String valueText,
              required double value,
              required double min,
              required double max,
              required int divisions,
              required ValueChanged<double> onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        valueText,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: value.clamp(min, max).toDouble(),
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            return AlertDialog(
              title: const Text(
                'تنظیم اندازه نمایشگر و دکمه‌ها',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildSlider(
                        title: 'ارتفاع نمایشگر',
                        valueText: '${(tempDisplayHeight * 100).round()}٪',
                        value: tempDisplayHeight,
                        min: 0.18,
                        max: 0.38,
                        divisions: 20,
                        onChanged: (value) {
                          setDialogState(() {
                            tempDisplayHeight = value;
                          });
                        },
                      ),
                      buildSlider(
                        title: 'اندازه عدد نتیجه',
                        valueText: '${tempResultFontSize.round()}',
                        value: tempResultFontSize,
                        min: 28,
                        max: 60,
                        divisions: 32,
                        onChanged: (value) {
                          setDialogState(() {
                            tempResultFontSize = value;
                          });
                        },
                      ),
                      buildSlider(
                        title: 'فاصله بین دکمه‌ها',
                        valueText: tempButtonSpacing.toStringAsFixed(1),
                        value: tempButtonSpacing,
                        min: 0,
                        max: 6,
                        divisions: 12,
                        onChanged: (value) {
                          setDialogState(() {
                            tempButtonSpacing = value;
                          });
                        },
                      ),
                      buildSlider(
                        title: 'اندازه نوشته دکمه‌ها',
                        valueText: '${tempButtonFontSize.round()}',
                        value: tempButtonFontSize,
                        min: 14,
                        max: 30,
                        divisions: 16,
                        onChanged: (value) {
                          setDialogState(() {
                            tempButtonFontSize = value;
                          });
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 6),
                      const Text(
                        'پس از تنظیم مقادیر، گزینه اعمال را بزنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempDisplayHeight = 0.27;
                      tempResultFontSize = 42;
                      tempButtonSpacing = 2;
                      tempButtonFontSize = 22;
                    });
                  },
                  child: const Text('بازنشانی'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('اعمال'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    setState(() {
      displayHeightFactor = tempDisplayHeight;
      resultFontSize = tempResultFontSize;
      buttonSpacing = tempButtonSpacing;
      buttonFontSize = tempButtonFontSize;
    });

    await _saveDisplaySettings();

    if (mounted) {
      _showMessage('تنظیمات اندازه ذخیره شد');
    }
  }

  // ==========================================
  // بارگذاری دکمه‌های اختصاصی
  // ==========================================

  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await FormulaStorage.load();

    if (!mounted) return;

    final newSlots = <String, String>{
      'x': prefs.getString('calculator_slot_x') ?? '',
      'y': prefs.getString('calculator_slot_y') ?? '',
      'z': prefs.getString('calculator_slot_z') ?? '',
    };

    final newNames = <String, String>{};

    for (final slot in ['x', 'y', 'z']) {
      final id = newSlots[slot] ?? '';

      if (id.isEmpty) {
        newNames[slot] = slot;
      } else if (id.startsWith('builtin:')) {
        newNames[slot] = _builtInDisplayName(
          id.substring('builtin:'.length),
        );
      } else {
        FormulaItem? match;

        for (final item in items) {
          if (item.id == id) {
            match = item;
            break;
          }
        }

        newNames[slot] = match?.name ?? slot;
      }
    }

    setState(() {
      slots = newSlots;
      slotNames = newNames;
    });
  }

  String _builtInDisplayName(String label) {
    switch (label) {
      case 'CHECK قبلی':
      case 'previous':
        return 'CHECK قبلی';
      case 'CHECK بعدی':
      case 'next':
        return 'CHECK بعدی';
      case 'تنظیم اعشار':
      case 'decimal':
        return 'تنظیم اعشار';
      case 'تنظیم رنگ‌ها':
      case 'colors':
        return 'تنظیم رنگ‌ها';
      case 'SAVE':
        return 'SAVE';
      case 'TXT خروجی':
        return 'TXT خروجی';
      case 'ذخیره‌ها':
        return 'ذخیره‌ها';
      case 'A% FROM B':
        return 'A% FROM B';
      case 'A%B=?':
        return 'A%B=?';
      case 'فرمول‌ها':
        return 'فرمول‌ها';
      case 'درصد عدد جاری':
      case 'percent':
        return '%';
      case 'پاک کردن نمایشگر':
      case 'clear':
        return 'AC';
      case 'حذف رقم آخر':
      case 'backspace':
        return 'Back';
      case 'محاسبه نتیجه':
      case 'equals':
        return '=';
      default:
        return label;
    }
  }

  // ==========================================
  // قالب‌بندی اعداد
  // ==========================================

  String formatInput(String value) {
    if (value.isEmpty) return '0';

    String sign = '';

    if (value.startsWith('-')) {
      sign = '-';
      value = value.substring(1);
    }

    final parts = value.split('.');
    String integerPart = parts[0].replaceAll(',', '');

    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(integerPart[i]);
    }

    if (parts.length > 1) {
      return '$sign${buffer.toString()}.${parts[1]}';
    }

    return '$sign${buffer.toString()}';
  }

  double parseDisplay(String value) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0;
  }

  String formatNumber(double value) {
    if (!value.isFinite) return 'Error';

    String fixed = value.toStringAsFixed(decimalPlaces);

    if (fixed.contains('.')) {
      fixed = fixed.replaceFirst(RegExp(r'0+$'), '');
      fixed = fixed.replaceFirst(RegExp(r'\.$'), '');
    }

    return formatInput(fixed);
  }

  // ==========================================
  // ورود اعداد و عملیات اصلی
  // ==========================================

  void inputNumber(String value) {
    setState(() {
      if (startNewNumber || display == 'Error') {
        display = value;
        startNewNumber = false;
        return;
      }

      final raw = display.replaceAll(',', '');

      if (raw.replaceAll('.', '').length >= 20) return;

      display = formatInput(raw + value);
    });
  }

  void inputDecimal() {
    setState(() {
      if (startNewNumber || display == 'Error') {
        display = '0.';
        startNewNumber = false;
      } else if (!display.contains('.')) {
        display += '.';
      }
    });
  }

  void selectOperator(String op) {
    if (firstNumber != null && operation != null) {
      calculate();
    }

    final current = parseDisplay(display);

    setState(() {
      firstNumber = current;
      operation = op;
      expression = '${formatNumber(current)} $op';
      startNewNumber = true;
    });
  }

  void calculate() {
    if (firstNumber == null || operation == null) return;

    final a = firstNumber!;
    final b = parseDisplay(display);

    double result;

    switch (operation) {
      case '+':
        result = a + b;
        break;
      case '−':
        result = a - b;
        break;
      case '×':
        result = a * b;
        break;
      case '÷':
        if (b == 0) {
          setState(() {
            display = 'Error';
            expression = '';
            firstNumber = null;
            operation = null;
            startNewNumber = true;
          });

          _showMessage('تقسیم بر صفر امکان‌پذیر نیست');
          return;
        }

        result = a / b;
        break;
      default:
        return;
    }

    final resultText = formatNumber(result);
    final calculationExpression =
        '${formatNumber(a)} $operation ${formatNumber(b)}';

    history.add(
      SavedCalculation(
        name: 'محاسبه ${history.length + 1}',
        expression: calculationExpression,
        result: resultText,
        dateTime: DateTime.now(),
      ),
    );

    historyIndex = history.length - 1;

    setState(() {
      expression = '$calculationExpression =';
      display = resultText;
      firstNumber = null;
      operation = null;
      startNewNumber = true;
    });
  }

  void clearAll() {
    setState(() {
      display = '0';
      expression = '';
      firstNumber = null;
      operation = null;
      startNewNumber = true;
    });
  }

  void backspace() {
    setState(() {
      if (startNewNumber || display == 'Error') {
        display = '0';
        startNewNumber = true;
        return;
      }

      String raw = display.replaceAll(',', '');

      if (raw.length <= 1) {
        display = '0';
        return;
      }

      raw = raw.substring(0, raw.length - 1);

      display = raw.isEmpty || raw == '-' ? '0' : formatInput(raw);
    });
  }

  void percent() {
    final value = parseDisplay(display);

    setState(() {
      display = formatNumber(value / 100);
      startNewNumber = true;
    });
  }

  // ==========================================
  // دریافت مقدار از کاربر
  // ==========================================

  Future<double?> _askNumber(String label) async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مقدار $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());

              if (value != null) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> percentageFrom() async {
    final a = await _askNumber('A');

    if (a == null || !mounted) return;

    final b = await _askNumber('B');

    if (b == null || !mounted) return;

    setState(() {
      expression = '$a% از $b';
      display = formatNumber((a / 100) * b);
      startNewNumber = true;
    });
  }

  Future<void> percentageOf() async {
    final a = await _askNumber('A');

    if (a == null || !mounted) return;

    final b = await _askNumber('B');

    if (b == null || !mounted) return;

    if (b == 0) {
      _showMessage('B نمی‌تواند صفر باشد');
      return;
    }

    setState(() {
      expression = '$a نسبت به $b';
      display = formatNumber((a / b) * 100);
      startNewNumber = true;
    });
  }

  // ==========================================
  // ذخیره محاسبه
  // ==========================================

  Future<void> saveCalculation() async {
    if (display == 'Error') {
      _showMessage('ابتدا یک محاسبه معتبر انجام دهید');
      return;
    }

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ذخیره محاسبه'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'نام محاسبه',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || !mounted) return;

    saved.add(
      SavedCalculation(
        name: name,
        expression: expression.isEmpty ? display : expression,
        result: display,
        dateTime: DateTime.now(),
      ),
    );

    setState(() {});
    _showMessage('محاسبه ذخیره شد');
  }

  Future<void> editSaved(int index) async {
    if (index < 0 || index >= saved.length) return;

    final controller = TextEditingController(text: saved[index].name);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش نام'),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'نام جدید',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || !mounted) return;

    final old = saved[index];

    saved[index] = SavedCalculation(
      name: name,
      expression: old.expression,
      result: old.result,
      dateTime: old.dateTime,
    );

    setState(() {});
  }

  void showSaved() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101317),
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: saved.isEmpty
                ? const Center(
                    child: Text('هنوز محاسبه‌ای ذخیره نشده است'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: saved.length,
                    itemBuilder: (context, index) {
                      final item = saved[index];

                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.expression} = ${item.result}\n'
                            '${_formatDate(item.dateTime)}',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  editSaved(index);
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  saved.removeAt(index);
                                  Navigator.pop(sheetContext);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');

    return '${date.year}/${two(date.month)}/${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  // ==========================================
  // خروجی متنی
  // ==========================================

  void exportTxt() {
    if (saved.isEmpty) {
      _showMessage('موردی برای خروجی وجود ندارد');
      return;
    }

    final buffer = StringBuffer()
      ..writeln('ماشین حساب پیشرفته')
      ..writeln('======================');

    for (final item in saved) {
      buffer
        ..writeln('نام: ${item.name}')
        ..writeln('محاسبه: ${item.expression}')
        ..writeln('نتیجه: ${item.result}')
        ..writeln('تاریخ: ${_formatDate(item.dateTime)}')
        ..writeln('----------------------');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    _showMessage('متن خروجی در کلیپ‌بورد کپی شد');
  }

  // ==========================================
  // پیمایش محاسبات قبلی
  // ==========================================

  void previousCalculation() {
    if (history.isEmpty) {
      _showMessage('تاریخچه‌ای وجود ندارد');
      return;
    }

    setState(() {
      if (historyIndex == -1) {
        historyIndex = history.length - 1;
      } else if (historyIndex > 0) {
        historyIndex--;
      }

      final item = history[historyIndex];

      expression = item.expression;
      display = item.result;
      startNewNumber = true;
    });
  }

  void nextCalculation() {
    if (history.isEmpty) {
      _showMessage('تاریخچه‌ای وجود ندارد');
      return;
    }

    setState(() {
      if (historyIndex == -1) {
        historyIndex = 0;
      } else if (historyIndex < history.length - 1) {
        historyIndex++;
      } else {
        return;
      }

      final item = history[historyIndex];

      expression = item.expression;
      display = item.result;
      startNewNumber = true;
    });
  }

  // ==========================================
  // تنظیم تعداد ارقام اعشار
  // ==========================================

  Future<void> chooseDecimalPlaces() async {
    int selected = decimalPlaces;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعداد ارقام اعشار'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selected رقم'),
              Slider(
                value: selected.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$selected',
                onChanged: (value) {
                  setDialogState(() {
                    selected = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        decimalPlaces = result;
      });
    }
  }

  // ==========================================
  // تنظیم رنگ‌ها
  // ==========================================

  Future<void> openColorSettings() async {
    await Navigator.pushNamed(context, '/colors');
    await CalculatorColors.load();

    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================
  // عملیات دکمه‌های اختصاصی
  // ==========================================

  Map<String, VoidCallback> _createActions() {
    return {
      'CHECK قبلی': previousCalculation,
      'CHECK بعدی': nextCalculation,
      'تنظیم اعشار': chooseDecimalPlaces,
      'تنظیم رنگ‌ها': openColorSettings,
      'SAVE': saveCalculation,
      'TXT خروجی': exportTxt,
      'ذخیره‌ها': showSaved,
      'A% FROM B': percentageFrom,
      'A%B=?': percentageOf,
      'فرمول‌ها': () {
        Navigator.pushNamed(context, '/formulas');
      },
      'درصد عدد جاری': percent,
      'پاک کردن نمایشگر': clearAll,
      'حذف رقم آخر': backspace,
      'محاسبه نتیجه': calculate,
    };
  }

  Future<void> openButtonsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomButtonsPage(
          actions: _createActions(),
          onCustomButton: executeCustomButton,
        ),
      ),
    );

    await _loadSlots();
  }

  Future<void> chooseSlotButton(String slot) async {
    final selectedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomButtonsPage(
          actions: _createActions(),
          onCustomButton: executeCustomButton,
          selectionMode: true,
        ),
      ),
    );

    if (selectedId == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('calculator_slot_$slot', selectedId);

    await _loadSlots();

    if (mounted) {
      _showMessage('دکمه $slot تغییر کرد');
    }
  }

  Future<void> executeCustomButton(FormulaItem item) async {
    if (item.type == 'value') {
      final number = double.tryParse(item.value);

      if (number == null) {
        _showMessage('مقدار ثابت معتبر نیست');
        return;
      }

      setState(() {
        expression = item.name;
        display = formatNumber(number);
        startNewNumber = true;
      });

      return;
    }

    if (item.type == 'function') {
      switch (item.value) {
        case 'percent':
          percent();
          break;
        case 'clear':
          clearAll();
          break;
        case 'backspace':
          backspace();
          break;
        case 'equals':
          calculate();
          break;
        case 'previous':
          previousCalculation();
          break;
        case 'next':
          nextCalculation();
          break;
        case 'save':
          await saveCalculation();
          break;
        case 'showSaved':
          showSaved();
          break;
        case 'exportTxt':
          exportTxt();
          break;
        case 'percentageFrom':
          await percentageFrom();
          break;
        case 'percentageOf':
          await percentageOf();
          break;
        default:
          _showMessage('عملکرد این دکمه شناخته نشد');
      }

      return;
    }

    if (item.type == 'formula') {
      final variables = RegExp(r'\b[A-Za-z][A-Za-z0-9_]*\b')
          .allMatches(item.value)
          .map((m) => m.group(0)!)
          .where(
            (v) => !{'pi', 'e'}.contains(v.toLowerCase()),
          )
          .toSet()
          .toList();

      final values = <String, double>{};

      for (final variable in variables) {
        final value = await _askNumber(variable);

        if (value == null || !mounted) return;

        values[variable] = value;
      }

      try {
        final result = evaluateFormula(item.value, values);

        setState(() {
          expression = item.name;
          display = formatNumber(result);
          startNewNumber = true;
        });
      } catch (e) {
        _showMessage('فرمول قابل محاسبه نیست: $e');
      }
    }
  }

  Future<void> tapSlot(String slot) async {
    final id = slots[slot] ?? '';

    if (id.isEmpty) {
      _showMessage('برای $slot هنوز دکمه‌ای اختصاص داده نشده است');
      return;
    }

    if (id.startsWith('builtin:')) {
      final label = id.substring('builtin:'.length);
      final actions = _createActions();

      final action = actions[label];

      if (action != null) {
        action();
        return;
      }

      switch (label) {
        case 'previous':
          previousCalculation();
          return;
        case 'next':
          nextCalculation();
          return;
        case 'decimal':
          await chooseDecimalPlaces();
          return;
        case 'colors':
          await openColorSettings();
          return;
        case 'percent':
          percent();
          return;
        case 'clear':
          clearAll();
          return;
        case 'backspace':
          backspace();
          return;
        case 'equals':
          calculate();
          return;
        default:
          _showMessage('عملکرد این دکمه شناخته نشد');
          return;
      }
    }

    final items = await FormulaStorage.load();

    FormulaItem? selected;

    for (final item in items) {
      if (item.id == id) {
        selected = item;
        break;
      }
    }

    if (selected == null) {
      _showMessage('دکمه اختصاص‌یافته پیدا نشد');
      await _loadSlots();
      return;
    }

    await executeCustomButton(selected);
  }

  // ==========================================
  // پیام‌های برنامه
  // ==========================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ==========================================
  // ساخت دکمه عمومی
  // ==========================================

  Widget squareButton({
    required String text,
    required VoidCallback onPressed,
    required Color background,
    required Color textColor,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    VoidCallback? onHold4Seconds,
  }) {
    Timer? holdTimer;
    bool holdTriggered = false;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: buttonSpacing,
          vertical: buttonSpacing / 2,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            holdTriggered = false;

            if (onHold4Seconds != null) {
              holdTimer?.cancel();

              holdTimer = Timer(
                const Duration(seconds: 4),
                () {
                  holdTriggered = true;
                  onHold4Seconds();
                },
              );
            }
          },
          onTapUp: (_) {
            holdTimer?.cancel();

            if (!holdTriggered) {
              onPressed();
            }

            holdTriggered = false;
          },
          onTapCancel: () {
            holdTimer?.cancel();
            holdTriggered = false;
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 1,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? buttonFontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // دکمه‌های اعداد
  // ==========================================

  Widget numberButton(
    String text,
    VoidCallback onPressed, {
    double? fontSize,
  }) {
    return squareButton(
      text: text,
      onPressed: onPressed,
      background: CalculatorColors.get('number'),
      textColor: CalculatorColors.get('buttonText'),
      fontSize: fontSize ?? buttonFontSize,
    );
  }

  // ==========================================
  // دکمه‌های عملیات
  // ==========================================

  Widget operatorButton(
    String text,
    VoidCallback onPressed, {
    VoidCallback? onHold4Seconds,
  }) {
    return squareButton(
      text: text,
      onPressed: onPressed,
      background: CalculatorColors.get('operator'),
      textColor: Colors.white,
      fontSize: text.length > 5 ? 12 : buttonFontSize,
      fontWeight: FontWeight.bold,
      onHold4Seconds: onHold4Seconds,
    );
  }

  // ==========================================
  // دکمه‌های کمکی
  // ==========================================

  Widget utilityButton(
    String text,
    VoidCallback onPressed, {
    double? fontSize,
  }) {
    return squareButton(
      text: text,
      onPressed: onPressed,
      background: CalculatorColors.get('utility'),
      textColor: CalculatorColors.get('buttonText'),
      fontSize: fontSize ?? buttonFontSize,
    );
  }

  Widget buildRow(List<Widget> children) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ==========================================
  // نمایشگر ماشین‌حساب
  // ==========================================

  Widget buildDisplay() {
    final recent = history.reversed.take(4).toList();

    final screenHeight = MediaQuery.of(context).size.height;

    final displayHeight =
        (screenHeight * displayHeightFactor).clamp(120.0, 300.0).toDouble();

    return Container(
      height: displayHeight,
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 3),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: CalculatorColors.get('display'),
        border: Border.all(
          color: const Color(0xFF292D31),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // محاسبات قبلی: چپ‌چین
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final item = recent[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    '${item.expression} = ${item.result}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: CalculatorColors.get('expressionText')
                          .withOpacity(0.38),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),

          // عبارت جاری
          SizedBox(
            height: 22,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                expression,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: CalculatorColors.get('expressionText'),
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),

          // نتیجه با اندازه قابل تنظیم
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  display,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: CalculatorColors.get('displayText'),
                    fontSize: resultFontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // دکمه‌های نوار بالای برنامه
  // ==========================================

  Widget topActionButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      constraints: const BoxConstraints(
        minWidth: 34,
        minHeight: 40,
      ),
    );
  }

  // ==========================================
  // صفحه اصلی
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final background = CalculatorColors.get('background');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: CalculatorColors.get('appBar'),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'ماشین‌حساب پیشرفته',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            topActionButton(
              label: 'محاسبه قبلی',
              onPressed: previousCalculation,
              icon: Icons.chevron_left,
            ),
            topActionButton(
              label: 'محاسبه بعدی',
              onPressed: nextCalculation,
              icon: Icons.chevron_right,
            ),
            topActionButton(
              label: 'تنظیم اعشار',
              onPressed: chooseDecimalPlaces,
              icon: Icons.tune,
            ),
            topActionButton(
              label: 'تنظیمات رنگ‌ها',
              onPressed: openColorSettings,
              icon: Icons.palette_outlined,
            ),
            topActionButton(
              label: 'دکمه‌های جانبی',
              onPressed: openButtonsPage,
              icon: Icons.grid_view,
            ),

            // منوی تنظیم اندازه نمایشگر و دکمه‌ها
            PopupMenuButton<String>(
              tooltip: 'تنظیم اندازه نمایشگر و دکمه‌ها',
              icon: const Icon(
                Icons.aspect_ratio,
                size: 21,
              ),
              onSelected: (value) {
                if (value == 'layout') {
                  openLayoutSettings();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'layout',
                  child: Row(
                    children: [
                      Icon(Icons.aspect_ratio),
                      SizedBox(width: 10),
                      Text('اندازه نمایشگر و دکمه‌ها'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              buildDisplay(),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        buildRow([
                          numberButton('7', () => inputNumber('7')),
                          numberButton('8', () => inputNumber('8')),
                          numberButton('9', () => inputNumber('9')),
                          operatorButton(
                            slotNames['x'] ?? 'x',
                            () => tapSlot('x'),
                            onHold4Seconds: () => chooseSlotButton('x'),
                          ),
                        ]),
                        buildRow([
                          numberButton('4', () => inputNumber('4')),
                          numberButton('5', () => inputNumber('5')),
                          numberButton('6', () => inputNumber('6')),
                          operatorButton(
                            slotNames['y'] ?? 'y',
                            () => tapSlot('y'),
                            onHold4Seconds: () => chooseSlotButton('y'),
                          ),
                        ]),
                        buildRow([
                          numberButton('1', () => inputNumber('1')),
                          numberButton('2', () => inputNumber('2')),
                          numberButton('3', () => inputNumber('3')),
                          operatorButton(
                            slotNames['z'] ?? 'z',
                            () => tapSlot('z'),
                            onHold4Seconds: () => chooseSlotButton('z'),
                          ),
                        ]),
                        buildRow([
                          numberButton('0', () => inputNumber('0')),
                          numberButton(
                            '00',
                            () => inputNumber('00'),
                            fontSize: 18,
                          ),
                          numberButton('.', inputDecimal),
                          numberButton(
                            '000',
                            () => inputNumber('000'),
                            fontSize: 17,
                          ),
                        ]),
                        buildRow([
                          operatorButton('+', () => selectOperator('+')),
                          operatorButton('-', () => selectOperator('−')),
                          operatorButton('*', () => selectOperator('×')),
                          operatorButton('/', () => selectOperator('÷')),
                        ]),
                        buildRow([
                          utilityButton('AC', clearAll),
                          utilityButton('Back', backspace),
                          utilityButton('%', percent),
                          operatorButton('=', calculate),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
