// lib/components/step_counter.dart
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class StepCounter extends StatefulWidget {
  final ValueChanged<int>? onStepChanged;

  const StepCounter({super.key, this.onStepChanged});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int steps = 0;
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepError);
  }

  void _onStepCount(StepCount event) {
    setState(() {
      steps = event.steps;
    });
    if (widget.onStepChanged != null) widget.onStepChanged!(steps);
  }

  void _onStepError(error) {
    print('Pedometer Error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      steps.toString(),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}
