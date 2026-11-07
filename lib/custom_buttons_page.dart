import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'formulas_page.dart';

class CustomButtonsPage extends StatefulWidget {
  final Map<String, VoidCallback> actions;
  final Future<void> Function(FormulaItem item) onCustomButton;

  // وقتی true باشد، صفحه برای انتخاب دکمه جهت x/y/z باز می‌شود.
  final bool selectionMode;

  const CustomButtonsPage({
    super.key,
    required this.actions,
    required this.onCustomButton,
    this.selectionMode = false,
  });

  @override
  State<CustomButtonsPage> createState() => _CustomButtonsPageState();
}

class _CustomButtonsPageState extends State<CustomButtonsPage> {
  List<FormulaItem> items = [];
  Map<String, String> slots = {};
  bool loading = true;

  static const slotKeys = ['x', 'y', 'z'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedItems = await FormulaStorage.load();

    if (!mounted) return;

    setState(() {
      items = loadedItems;
      slots = {
        for (final key in slotKeys)
          key: prefs.getString('calculator_slot_$key') ?? '',
      };
      loading = false;
    });
  }

  Future<void> _assignSlot(String slot) async {
    final selectedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomButtonsPage(
          actions: widget.actions,
          onCustomButton: widget.onCustomButton,
          selectionMode: true,
        ),
      ),
    );

    if (selectedId == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculator_slot_$slot', selectedId);

    if (!mounted) return;

    setState(() {
      slots[slot] = selectedId;
    });
  }

  Future<void> _clearSlot(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calculator_slot_$slot');

    if (!mounted) return;

    setState(() {
      slots[slot] = '';
    });
  }

  Future<void> _addButton() async {
    await Navigator.pushNamed(context, '/add-button');
    await _load();
  }

  String _slotName(String slot) {
    final id = slots[slot] ?? '';

    if (id.startsWith('builtin:')) {
      return id.substring('builtin:'.length);
    }

    for (final item in items) {
      if (item.id == id) return item.name;
    }

    return 'تعریف نشده';
  }

  void _selectBuiltIn(String label) {
    Navigator.pop(context, 'builtin:$label');
  }

  void _selectCustom(FormulaItem item) {
    Navigator.pop(context, item.id);
  }

  Widget _actionTile({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: const Color(0xFFD4D5D5),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      childAspectRatio: 1.15,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final builtInActions = widget.actions.entries.toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.selectionMode
                ? 'انتخاب دکمه برای جایگزینی'
                : 'دکمه‌های جانبی',
          ),
          actions: [
            if (!widget.selectionMode)
              IconButton(
                tooltip: 'مدیریت فرمول‌ها',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FormulasPage(),
                    ),
                  );
                  await _load();
                },
                icon: const Icon(Icons.functions),
              ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  if (widget.selectionMode) ...[
                    const Text(
                      'یکی از دکمه‌های زیر را انتخاب کن. نام و عملکرد همان دکمه برای جایگاه انتخاب‌شده استفاده می‌شود.',
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    const Text(
                      'اختصاص دکمه به x، y و z',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...slotKeys.map(
                      (slot) => Card(
                        child: ListTile(
                          title: Text('جایگاه $slot'),
                          subtitle: Text(_slotName(slot)),
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                tooltip: 'انتخاب دکمه',
                                onPressed: () => _assignSlot(slot),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'خالی کردن',
                                onPressed: () => _clearSlot(slot),
                                icon: const Icon(Icons.clear),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                  ],
                  const Text(
                    'عملکردهای آماده',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _grid(
                    builtInActions.map((entry) {
                      return _actionTile(
                        label: entry.key,
                        onTap: () {
                          if (widget.selectionMode) {
                            _selectBuiltIn(entry.key);
                          } else {
                            entry.value();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 28),
                  const Text(
                    'دکمه‌های ساخته‌شده',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'هنوز دکمه‌ای ساخته نشده است.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    _grid(
                      items.map((item) {
                        return _actionTile(
                          label: item.name,
                          onTap: () {
                            if (widget.selectionMode) {
                              _selectCustom(item);
                            } else {
                              widget.onCustomButton(item);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  if (!widget.selectionMode) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _addButton,
                        icon: const Icon(Icons.add),
                        label: const Text('دکمه جدید'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
