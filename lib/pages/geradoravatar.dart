import 'package:flutter/material.dart';

class GeradorAvatarScreen extends StatelessWidget {
  const GeradorAvatarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Avatar'),
        backgroundColor: const Color(0xFFF1F1F1),
      ),
      body: Center(
        child: Text('Página do Gerador de Avatar'),
      ),
    );
  }
}