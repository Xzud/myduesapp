import 'package:flutter/material.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/injection_container.dart';

class DuesPage extends StatefulWidget {
  const DuesPage({super.key});

  @override
  State<DuesPage> createState() => _DuesPageState();
}

class _DuesPageState extends State<DuesPage> {
  final controller = sl<DueController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dues')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final dues = controller.dues;

          bool checkComplete(due) {
            for (var item in due.dues) {
              if (!item.paid) {
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
                          due.month,
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
                              for (var item in due.dues)
                                CheckboxListTile(
                                  title: Text(
                                    '${item.name} - Php ${item.price}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: item.paid
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  value: item.paid,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      item.paid = value ?? false;
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
