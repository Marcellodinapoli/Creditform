import 'package:flutter/material.dart';

class PageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBackButton;  // nuovo parametro opzionale
  final String backButtonText; // testo del pulsante indietro (default: 'Ritorna')

  const PageWrapper({
    Key? key,
    required this.title,
    required this.child,
    this.showBackButton = false,  // di default non mostra la freccia
    this.backButtonText = 'Ritorna', // default testo pulsante
  }) : super(key: key);

  static const double maxContentWidth = 1300;
  static const double horizontalPadding = 24;
  static const double verticalPadding = 16;

  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white, // titolo bianco nell'appbar
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const Color appBarColor = Color(0xFF1565C0); // blu scuro personalizzato

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: titleStyle),
        backgroundColor: appBarColor,
        centerTitle: true,
        leading: showBackButton
            ? InkWell(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                if (backButtonText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    backButtonText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        )
            : null,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: DefaultTextStyle(
              style: bodyStyle,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
