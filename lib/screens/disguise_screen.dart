import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class DisguiseScreen extends StatefulWidget {
  const DisguiseScreen({super.key});

  @override
  State<DisguiseScreen> createState() => _DisguiseScreenState();
}

class _DisguiseScreenState extends State<DisguiseScreen> {
  String _display = '0';
  int _equalsCount = 0;
  DateTime? _lastEqualsTime;

  void _onButtonPressed(String value) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (value == '=') {
      final now = DateTime.now();
      if (_lastEqualsTime != null &&
          now.difference(_lastEqualsTime!).inMilliseconds < 500) {
        _equalsCount++;
        if (_equalsCount >= 5) {
          provider.toggleDisguiseMode();
          _equalsCount = 0;
          return;
        }
      } else {
        _equalsCount = 1;
      }
      _lastEqualsTime = now;

      try {
        setState(() {
          _display = _evaluateExpression(_display);
        });
      } catch (e) {
        setState(() {
          _display = 'Error';
        });
      }
    } else if (value == 'C') {
      setState(() {
        _display = '0';
      });
    } else if (value == '±') {
      setState(() {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      });
    } else if (value == '%') {
      setState(() {
        _display = (double.tryParse(_display) ?? 0 / 100).toString();
      });
    } else {
      setState(() {
        if (_display == '0' && value != '.') {
          _display = value;
        } else {
          _display += value;
        }
      });
    }
  }

  String _evaluateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
    return expr; // simplified
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              ..._buildButtonRows(),
              const SizedBox(height: 16),
              Text(
                'Tap "=" 5 times quickly to exit',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtonRows() {
    final buttons = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '0', '.', '='],
    ];

    return buttons.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: row.asMap().entries.map((entry) {
            final index = entry.key;
            final btn = entry.value;
            final isOperator = ['÷', '×', '−', '+', '='].contains(btn);
            final isZero = btn == '0' && index == 0 && row[1] == '0';

            return Expanded(
              flex: isZero ? 2 : 1,
              child: Padding(
                padding: EdgeInsets.only(right: index < row.length - 1 ? 12 : 0),
                child: isZero && index == 1
                    ? const SizedBox()
                    : _buildButton(btn, isOperator),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildButton(String text, bool isOperator) {
    return GestureDetector(
      onTap: () => _onButtonPressed(text),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isOperator ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
