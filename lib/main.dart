import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:control_pad/control_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ssh/ssh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras[1];

  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: HomePage(camera: frontCamera),
  ));
}

class HomePage extends StatefulWidget {
  final CameraDescription camera;
  final String title = "Robopet";

  const HomePage({Key key, @required this.camera}) : super(key: key);

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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                UsersPage(camera: widget.camera)));
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
  SSHClient client;

  void startSession() async {
    try {
      await client.connect();
      await client.startShell(
          ptyType: "xterm",
          callback: (dynamic result) {
            print(result);
          }
      );
      await client.writeToShell("cd ~/robopet_be\n");
      await client.writeToShell("./test.py\n");
      final snackBar = SnackBar(content: Text("Connection Established"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on PlatformException catch (e) {
      final snackBar = SnackBar(content: Text("Connection failed: $e"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.pop(context);
    }
  }

  void initState() {
    super.initState();
    client = new SSHClient(
      host: "10.0.0.5",
      port: 22,
      username: "pi",
      passwordOrKey: "***",
    );
    startSession();
  }

  void dispose() {
    client.closeShell();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   // startSession();

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: RotatedBox(
          quarterTurns: 3,
          child: Center(
            child: JoystickView(
              interval: Duration(milliseconds: 50),
              onDirectionChanged: (double degrees, double disFromCenter) {
                //client.execute("echo ${degrees} >> ~/test");
                // client.writeToShell("$degrees\n");
                if (degrees <= 180) {
                  client.writeToShell("${degrees.round()}\n");
                  print("${degrees.round()}");
                } else {
                  client.writeToShell("${(-1 * (360 - degrees)).round()}\n");
                  print("${(-1 * (360 - degrees)).round()}");
                }
              },
            ),
          ),
        )
    );
   }
}


class User {
  final String name;
  final String uid;

  User(this.name, this.uid);
}

class UsersPage extends StatefulWidget {
  final CameraDescription camera;

  UsersPage({Key key, @required this.camera}) : super(key: key);
  final String title = "Users";

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  final List<User> users = [User("Asaf", "")];

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: <Widget>[
        Padding(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User Name',
              ),
            )),
        ElevatedButton(
          child: Text('Add'),
          onPressed: () {
            _addUser();
          },
        ),
        Expanded(
            child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              height: 50,
              margin: EdgeInsets.all(2),
              color: Colors.green,
              child: ElevatedButton(
                child: Text('${users[index].name}'),
                onPressed: () {},
              ),
              // child: Center(
              //   child: Text('${users[index].name}',
              //       style: TextStyle(fontSize: 18)),
              // )
            );
          },
        ))
      ]),
    );
  }

  Future<String> _sendUserToRobot(String photoPath) async {
    final String url = "http://10.0.0.4:3000/upload";
    var request = http.MultipartRequest('PUT', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('picture', photoPath));

    // Throws TimeoutException if timeout passes
    http.Response response =
        await http.Response.fromStream(await request.send());

    if (response.statusCode != 201) {
      throw Exception("File transfer to robot failed");
    } else {
      return "1";
    }
  }

  void _updateUsersList(String photoPath) async {
    try {
      var uid = await _sendUserToRobot(photoPath);
      setState(() {
        users.insert(0, User(nameController.text, uid));
      });
      Navigator.pop(context);
      Navigator.pop(context);
      final snackbar = SnackBar(content: Text("Success: $uid"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on SocketException catch (e) {
      Navigator.pop(context);
      Navigator.pop(context);
      final snackbar = SnackBar(content: Text("File transfer timed out"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on Exception catch (e) {
      Navigator.pop(context);
      Navigator.pop(context);
      final snackbar = SnackBar(content: Text("$e"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  void _addUser() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Take picture")),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera_alt),
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller.takePicture();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return Scaffold(
                    appBar: AppBar(title: Text("Confirm Photo")),
                    body: Column(
                      children: [
                        Image.file(File(image?.path)),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                child: Text('Confirm'),
                                onPressed: () => _updateUsersList(image.path),
                              ),
                            ),
                            Expanded(
                                child: ElevatedButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    })),
                          ],
                        )
                      ],
                    ));
              }));
            } catch (e) {
              print(e);
            }
          },
        ),
      );
    }));
  }
}
