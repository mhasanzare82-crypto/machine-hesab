import 'package:flutter/material.dart';
import 'formulas_page.dart';

class AddButtonPage extends StatefulWidget {
  const AddButtonPage({super.key});

  @override
  State<AddButtonPage> createState() => _AddButtonPageState();
}

class _AddButtonPageState extends State<AddButtonPage> {
  final nameController = TextEditingController();
  final valueController = TextEditingController();

  String type = 'value';
  String function = 'percent';
  FormulaItem? existing;

  final Map<String, String> functions = const {
    'percent': 'درصد عدد جاری',
    'clear': 'پاک کردن نمایشگر',
    'backspace': 'حذف رقم آخر',
    'equals': 'محاسبه نتیجه',
    'previous': 'محاسبه قبلی',
    'next': 'محاسبه بعدی',
    'save': 'ذخیره محاسبه',
    'showSaved': 'نمایش محاسبات ذخیره‌شده',
    'exportTxt': 'خروجی متنی',
    'percentageFrom': 'A درصد از B',
    'percentageOf': 'A چند درصد B است؟',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FormulaItem && existing == null) {
      existing = args;
      nameController.text = args.name;
      type = args.type;
      if (type == 'function') {
        function = args.value;
      } else {
        valueController.text = args.value;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final value = type == 'function' ? function : valueController.text.trim();

    if (name.isEmpty || value.isEmpty) {
      _message('نام و مقدار را وارد کنید');
      return;
    }

    if (type == 'value' && double.tryParse(value) == null) {
      _message('مقدار ثابت باید عددی باشد');
      return;
    }

    if (type == 'formula') {
      try {
        final variables = RegExp(r'\b[A-Za-z][A-Za-z0-9_]*\b')
            .allMatches(value)
            .map((m) => m.group(0)!)
            .where((v) => !{'pi', 'e'}.contains(v.toLowerCase()))
            .toSet();

        evaluateFormula(
          value,
          {for (final v in variables) v: 1},
        );
      } catch (_) {
        // فرمول‌هایی که متغیر دارند هنگام اجرا مقدار می‌گیرند.
        // خطاهای نحوی نیز هنگام اجرای فرمول بررسی خواهند شد.
      }
    }

    final item = FormulaItem(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: type,
      value: value,
    );

    await FormulaStorage.upsert(item);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'تعریف دکمه جدید' : 'ویرایش دکمه'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'نام دکمه',
              hintText: 'مثلاً قیمت نهایی',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(
              labelText: 'نوع دکمه',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'value',
                child: Text('مقدار ثابت'),
              ),
              DropdownMenuItem(
                value: 'formula',
                child: Text('فرمول'),
              ),
              DropdownMenuItem(
                value: 'function',
                child: Text('عملکرد'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => type = v);
            },
          ),
          const SizedBox(height: 16),
          if (type == 'value')
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'مقدار عددی',
                hintText: '4350.25',
                border: OutlineInputBorder(),
              ),
            ),
          if (type == 'formula')
            TextField(
              controller: valueController,
              maxLines: 3,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'فرمول',
                hintText: '(A * B) / 100',
                helperText: 'نمونه: A * B / 100 یا (A + B) * 2',
                border: OutlineInputBorder(),
              ),
            ),
          if (type == 'function')
            DropdownButtonFormField<String>(
              value: function,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'عملکرد دکمه',
                border: OutlineInputBorder(),
              ),
              items: functions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => function = v);
              },
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('ذخیره دکمه'),
          ),
        ],
      ),
    );
  }
}
