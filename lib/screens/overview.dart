import 'package:flutter/material.dart';
import 'package:myduesapp/core/database_helper.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final Future<List<Map<String, dynamic>>> _duesFuture = DatabaseHelper.instance
      .getDues();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Overview')),
      body: FutureBuilder(
        future: _duesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dues = snapshot.data ?? [];

          bool checkComplete(due) {
            for (var item in due['dues']) {
              if (!item['paid']) {
                return false;
              }
            }
            return true;
          }

          if (dues.isEmpty) {
            return const Center(child: Text('No dues found.'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                for (var due in dues)
                  if (!checkComplete(due))
                    Column(
                      children: [
                        Text(
                          due['month'],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            children: [
                              for (var item in due['dues'])
                                CheckboxListTile(
                                  title: Text(
                                    '${item['name']} - Php ${item['price']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: item['paid']
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  value: item['paid'],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      item['paid'] = value ?? false;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
