import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormulaItem {
  final String id;
  final String name;
  final String type; // value, formula, function
  final String value;

  const FormulaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'value': value,
      };

  factory FormulaItem.fromJson(Map<String, dynamic> json) {
    return FormulaItem(
      id: json['id'].toString(),
      name: json['name'].toString(),
      type: json['type'].toString(),
      value: json['value'].toString(),
    );
  }
}

class FormulaStorage {
  static const String storageKey = 'calculator_formula_items';

  static Future<List<FormulaItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => FormulaItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<FormulaItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> upsert(FormulaItem item) async {
    final items = await load();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await save(items);
  }

  static Future<void> delete(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await save(items);
  }
}

double evaluateFormula(String formula, Map<String, double> variables) {
  return _FormulaParser(formula, variables).parse();
}

class FormulasPage extends StatefulWidget {
  const FormulasPage({super.key});

  @override
  State<FormulasPage> createState() => _FormulasPageState();
}

class _FormulasPageState extends State<FormulasPage> {
  List<FormulaItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await FormulaStorage.load();
    if (!mounted) return;
    setState(() {
      items = result;
      loading = false;
    });
  }

  String _typeName(String type) {
    switch (type) {
      case 'value':
        return 'مقدار ثابت';
      case 'formula':
        return 'فرمول';
      case 'function':
        return 'عملکرد';
      default:
        return type;
    }
  }

  Future<void> _add() async {
    await Navigator.pushNamed(context, '/add-button');
    await _load();
  }

  Future<void> _edit(FormulaItem item) async {
    await Navigator.pushNamed(
      context,
      '/add-button',
      arguments: item,
    );
    await _load();
  }

  Future<void> _delete(FormulaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دکمه'),
        content: Text('آیا «${item.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FormulaStorage.delete(item.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فرمول‌ها و مقادیر')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'هنوز دکمه‌ای تعریف نشده است.\n'
                    'برای افزودن دکمه، + را بزنید.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${_typeName(item.type)}: ${item.value}',
                          textDirection: TextDirection.ltr,
                        ),
                        leading: Icon(
                          item.type == 'value'
                              ? Icons.numbers
                              : item.type == 'formula'
                                  ? Icons.functions
                                  : Icons.play_circle_outline,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (choice) {
                            if (choice == 'edit') {
                              _edit(item);
                            } else {
                              _delete(item);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('ویرایش'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _FormulaParser {
  final String input;
  final Map<String, double> variables;
  int position = 0;

  _FormulaParser(this.input, this.variables);

  double parse() {
    final result = _expression();
    _skipSpaces();
    if (position != input.length) {
      throw const FormatException('فرمول نامعتبر است');
    }
    if (!result.isFinite) {
      throw const FormatException('نتیجه معتبر نیست');
    }
    return result;
  }

  void _skipSpaces() {
    while (position < input.length && input[position].trim().isEmpty) {
      position++;
    }
  }

  bool _take(String char) {
    _skipSpaces();
    if (position < input.length && input[position] == char) {
      position++;
      return true;
    }
    return false;
  }

  double _expression() {
    double result = _term();
    while (true) {
      if (_take('+')) {
        result += _term();
      } else if (_take('-') || _take('−')) {
        result -= _term();
      } else {
        return result;
      }
    }
  }

  double _term() {
    double result = _factor();
    while (true) {
      if (_take('*') || _take('×')) {
        result *= _factor();
      } else if (_take('/') || _take('÷')) {
        final divisor = _factor();
        if (divisor == 0) {
          throw const FormatException('تقسیم بر صفر');
        }
        result /= divisor;
      } else {
        return result;
      }
    }
  }

  double _factor() {
    _skipSpaces();

    if (_take('+')) return _factor();
    if (_take('-') || _take('−')) return -_factor();

    if (_take('(')) {
      final result = _expression();
      if (!_take(')')) {
        throw const FormatException('پرانتز بسته نشده است');
      }
      return result;
    }

    _skipSpaces();
    if (position >= input.length) {
      throw const FormatException('مقدار مورد انتظار بود');
    }

    final start = position;

    if (RegExp(r'[0-9.]').hasMatch(input[position])) {
      while (position < input.length &&
          RegExp(r'[0-9.]').hasMatch(input[position])) {
        position++;
      }
      final number = double.tryParse(input.substring(start, position));
      if (number == null) {
        throw const FormatException('عدد نامعتبر است');
      }
      return number;
    }

    if (RegExp(r'[A-Za-z_]').hasMatch(input[position])) {
      while (position < input.length &&
          RegExp(r'[A-Za-z0-9_]').hasMatch(input[position])) {
        position++;
      }

      final name = input.substring(start, position);
      if (name.toLowerCase() == 'pi') return 3.141592653589793;
      if (name.toLowerCase() == 'e') return 2.718281828459045;

      final value = variables[name];
      if (value == null) {
        throw FormatException('متغیر $name مقدار ندارد');
      }
      return value;
    }

    throw const FormatException('فرمول نامعتبر است');
  }
}
