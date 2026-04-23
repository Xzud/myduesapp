import 'package:flutter/material.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final List<Map<String, dynamic>> dues = [
    {
      "month": "March 2024",
      "dues": [
        {"name": "Netflix", "price": 15, "paid": false},
        {"name": "YouTube Premium", "price": 10, "paid": false},
      ],
    },
    {
      "month": "April 2024",
      "dues": [
        {"name": "Spotify", "price": 10, "paid": false},
        {"name": "Disney+", "price": 12, "paid": false},
      ],
    },
    {
      "month": "May 2024",
      "dues": [
        {"name": "Amazon Prime", "price": 15, "paid": false},
      ],
    },
    {
      "month": "June 2024",
      "dues": [
        {"name": "Hulu", "price": 20, "paid": false},
        {"name": "HBO Max", "price": 25, "paid": false},
      ],
    },
  ];

  bool _checkComplete(Map<String, dynamic> due) {
    for (var item in due['dues']) {
      if (!item['paid']) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Overview')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (var due in dues)
              if (!_checkComplete(due))
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
      ),
    );
  }
}
