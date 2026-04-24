import 'package:flutter/material.dart';
import 'package:myduesapp/%20models/due_model.dart';
import 'package:myduesapp/core/database_helper.dart';
import 'package:myduesapp/screens/overview.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'MyDues'),
      routes: {'/overview': (context) => OverviewPage()},
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();

  late DueModel due;

  @override
  void initState() {
    super.initState();
    _resetForm(); // Clear form on initial load
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _amountController.clear();
      _dateController.clear();
      _intervalController.clear();

      due = DueModel(
        name: '',
        amount: 0,
        recurring: false,
        recurringInterval: 0,
        dayOfMonth: 0,
        paid: false,
        complete: false,
      );
    });
  }

  void submitDue() async {
    final db = await DatabaseHelper.instance.database;

    due.create(db);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                // Navigate if needed
              },
            ),
            ListTile(
              title: Text('Overview'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => OverviewPage()),
                // );
                Navigator.pushNamed(context, '/overview');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          // mainAxisAlignment: .center,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 10,
            children: [
              // const Text('You have pushed the button this many times:'),
              // Text(
              //   '$_counter',
              //   style: Theme.of(context).textTheme.headlineMedium,
              // ),
              Text(
                'Add a new due',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  spacing: 8,
                  children: [
                    TextField(
                      controller: _nameController, // Bind controller
                      onChanged: (value) => due.name = value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Title',
                        hintText: 'Enter the title of your due',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextField(
                      controller: _amountController,
                      onChanged: (value) =>
                          due.amount = double.tryParse(value) ?? 0,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Amount',
                        hintText: 'Enter the amount of your due',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextField(
                      controller: _dateController,
                      onChanged: (value) => due.dayOfMonth = int.parse(value),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date',
                        hintText: 'Enter the date of your due',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          due.recurring = !due.recurring;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(value: due.recurring, onChanged: null),
                          const Text("Recurring"),
                        ],
                      ),
                    ),
                    if (due.recurring)
                      TextField(
                        controller: _intervalController,
                        onChanged: (value) =>
                            due.recurringInterval = int.parse(value),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Recurring',
                          hintText: 'How often does this due recur?',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _resetForm();
                          },
                          child: const Text('Clear'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            submitDue();
                            Navigator.pushNamed(context, '/overview');
                          },
                          child: const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
