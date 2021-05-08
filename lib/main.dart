import 'package:control_pad/control_pad.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);
  final String title = "Robopet";

  @override
  _HomePageState createState() => _HomePageState();
}

// Should preserve state - is logged in?
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(top: 15, bottom: 15),
                constraints: BoxConstraints.tightFor(height: 50, width: 150),
                child: ElevatedButton(
                  child: Text("Movement Control"),
                  onPressed: () {
                    Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Movement()));
                  },
                )),
              Container(
                margin: EdgeInsets.only(top: 15, bottom: 15),
                constraints: BoxConstraints.tightFor(height: 50, width: 150),
                child: ElevatedButton(
                  child: Text("Users"),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => UsersPage()));
                  },
                )),
          ],
        )));
  }
}

class Movement extends StatefulWidget {
  final String title = "Robopet Movement Control";

  @override
  _MovementState createState() => _MovementState();
}

class _MovementState extends State<Movement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: JoystickView(),
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  UsersPage({Key key}) : super(key: key);
  final String title = "Users";

  @override
  _UsersPageState createState() => _UsersPageState();
}



class _UsersPageState extends State<UsersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add user',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
