import 'package:flutter/material.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';
import 'package:myduesapp/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController controller;
  final TextEditingController dateInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = sl<SettingsController>();

    controller.fetchPaymentDates();
  }

  @override
  void dispose() {
    dateInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final paymentDates = controller.paymentDates;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 10,
                children: [
                  Center(child: Text('Settings Page')),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateInput,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: false,
                            signed: false,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter payment date of the month.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      spacing: 5,
                      children: [
                        for (var date in paymentDates.asMap().entries)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.red[100],
                            ),

                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 5,
                              ),
                              child: Row(
                                spacing: 10,
                                children: [
                                  Expanded(child: Text(date.value)),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      controller.removePaymentDate(date.key);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      // Add the entered payment date to the list
                      controller.addPaymentDate(dateInput.text);
                      dateInput.clear();
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.white),
                    ),
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
