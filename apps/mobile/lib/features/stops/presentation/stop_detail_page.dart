import 'package:flutter/material.dart';

class StopDetailPage extends StatelessWidget {
  const StopDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Detail $id — Task 19')));
}
