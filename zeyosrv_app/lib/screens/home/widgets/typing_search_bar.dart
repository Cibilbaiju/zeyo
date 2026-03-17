import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';

class TypingSearchBar extends StatefulWidget {
  const TypingSearchBar({super.key});

  @override
  State<TypingSearchBar> createState() => _TypingSearchBarState();
}

class _TypingSearchBarState extends State<TypingSearchBar> {
  final List<String> services = [
    "plumber",
    "cleaner",
    "electrician",
    "painter",
    "tree cutter",
    "scanner",
    "carpenter",
    "mechanic"
  ];

  int _currentServiceIndex = 0;
  String _displayText = "";
  bool _isTyping = true;
  String _userInput = "";
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _tick();
  }

  void _tick() {
    if (_focusNode.hasFocus || _userInput.isNotEmpty) return;

    final currentService = services[_currentServiceIndex];
    const baseText = "Search for ";
    
    // Typing
    if (_isTyping) {
      if (_displayText.length < baseText.length + currentService.length) {
        _timer = Timer(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          setState(() {
            if (_displayText.length < baseText.length) {
              _displayText = baseText.substring(0, _displayText.length + 1);
            } else {
              final serviceCharIndex = _displayText.length - baseText.length;
               _displayText = baseText + currentService.substring(0, serviceCharIndex + 1);
            }
          });
          _tick();
        });
      } else {
        // Wait then delete
        _timer = Timer(const Duration(seconds: 2), () {
           if (!mounted) return;
           setState(() => _isTyping = false);
           _tick();
        });
      }
    } else {
      // Deleting
      if (_displayText.length > baseText.length) {
         _timer = Timer(const Duration(milliseconds: 50), () {
           if (!mounted) return;
           setState(() {
             _displayText = _displayText.substring(0, _displayText.length - 1);
           });
           _tick();
         });
      } else {
        // Next service
        setState(() {
          _currentServiceIndex = (_currentServiceIndex + 1) % services.length;
          _isTyping = true;
        });
        _tick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(LucideIcons.search, size: 20, color: AppTheme.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (!_focusNode.hasFocus && _userInput.isEmpty)
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: _displayText),
                            const TextSpan(
                              text: "|",
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      focusNode: _focusNode,
                      onChanged: (val) {
                        setState(() => _userInput = val);
                        if (val.isEmpty) _startAnimation();
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        hintText: (_focusNode.hasFocus || _userInput.isNotEmpty) ? "Search for services..." : "",
                        hintStyle: const TextStyle(color: Colors.transparent), // Hide actual hint
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
