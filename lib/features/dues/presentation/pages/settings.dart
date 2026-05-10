import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> paymentDates = [];
  String dateInput = '';
  //TODO use controllers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
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
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter payment date of the month.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      dateInput = value;
                    },
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    // Add the entered payment date to the list
                    setState(() {
                      paymentDates.add(dateInput);
                    });
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
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
                                setState(() {
                                  paymentDates.removeAt(date.key);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
