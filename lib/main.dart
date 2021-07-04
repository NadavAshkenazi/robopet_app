import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:control_pad/control_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ssh/ssh.dart';

const String robotIP = "192.168.2.1";
const String httpPort = "3000";

class Dialogs {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  key: key,
                  backgroundColor: Colors.black54,
                  children: <Widget>[
                    Center(
                      child: Column(children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10,),
                        Text("Please Wait....",style: TextStyle(color: Colors.blueAccent),)
                      ]),
                    )
                  ]));
        });
  }
}

class OpenCVException implements Exception {
  final String cause;
  OpenCVException(this.cause);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras[1];

  runApp(MaterialApp(
    title: 'Flutter Demo',
    debugShowCheckedModeBanner: false,
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
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/logo_cropped.png",
            ),
          ),
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
                  child: Text("Head Control"),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HeadMovement()));
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
            Container(
                margin: EdgeInsets.only(top: 15, bottom: 15),
                constraints: BoxConstraints.tightFor(height: 50, width: 150),
                child: ElevatedButton(
                  child: Text("Behavior"),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => BehaviorControl()));
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
      await client.writeToShell("./movement.py\n");
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
      host: robotIP,
      port: 22,
      username: "pi",
      passwordOrKey: "robopet",
    );
    //startSession();
  }

  void dispose() {
    client.closeShell();
    client.disconnect();
    super.dispose();
  }

  void _sendHttpBehaviorReq(String behvaior, BuildContext context) async {
    final String url = "http://$robotIP:$httpPort/$behvaior";
    var request = http.Request('PUT', Uri.parse(url));
    try {
      var response = await request.send();
      if (response.statusCode != 204) {
        throw Exception("Bad status code: ${response.statusCode}");
      }
    } on Exception catch (e) {
      final snackbar = SnackBar(content: Text("Behvaior request failed: $e"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  @override
  Widget build(BuildContext context) {
    startSession();

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/logo_cropped.png",
            ),
          ),
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: JoystickView(
                  interval: Duration(milliseconds: 300),
                  onDirectionChanged: (double degrees, double disFromCenter) {
                    var actualDegrees = 0.0;
                    if (degrees <= 180) {
                      actualDegrees = 60 + (degrees / 3);
                    } else {
                      actualDegrees = (degrees - 360) / 3 - 60;
                    }
                    if (disFromCenter == 0) {
                      client.writeToShell("0\n");
                    } else {
                      client.writeToShell("${actualDegrees.round()}\n");
                    }
                  },
                ),
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Spin"),
                    onPressed: () {
                      _sendHttpBehaviorReq("spin", context);
                    },
                  )),
            ),
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Wag tail"),
                    onPressed: () {
                      _sendHttpBehaviorReq("wag", context);
                    },
                  )),
            ),
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Bark"),
                    onPressed: () {
                      _sendHttpBehaviorReq("bark", context);
                    },
                  )),
            ),
          ],)
        ],)
    );
   }
}

class HeadMovement extends StatefulWidget {
  final String title = "Robopet Head Movement Control";

  @override
  _HeadMovementState createState() => _HeadMovementState();
}

class _HeadMovementState extends State<HeadMovement> {
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
      await client.writeToShell("./headMovement.py\n");
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
      host: robotIP,
      port: 22,
      username: "pi",
      passwordOrKey: "robopet",
    );
    //startSession();
  }

  void dispose() {
    client.closeShell();
    client.disconnect();
    super.dispose();
  }

  void _sendHttpBehaviorReq(String behvaior, BuildContext context) async {
    final String url = "http://$robotIP:$httpPort/$behvaior";
    var request = http.Request('PUT', Uri.parse(url));
    try {
      var response = await request.send();
      if (response.statusCode != 204) {
        throw Exception("Bad status code: ${response.statusCode}");
      }
    } on Exception catch (e) {
      final snackbar = SnackBar(content: Text("Behvaior request failed: $e"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  @override
  Widget build(BuildContext context) {
    startSession();

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/logo_cropped.png",
            ),
          ),
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: RotatedBox(
              quarterTurns: 0,
              child: Center(
                child: JoystickView(
                  interval: Duration(milliseconds: 300),
                  onDirectionChanged: (double degrees, double disFromCenter) {
                    if (disFromCenter == 0) {
                      client.writeToShell("0\n");
                    } else {
                      client.writeToShell("${degrees.round()}\n");
                    }
                  },
                ),
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Spin"),
                    onPressed: () {
                      _sendHttpBehaviorReq("spin", context);
                    },
                  )),
            ),
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Wag tail"),
                    onPressed: () {
                      _sendHttpBehaviorReq("wag", context);
                    },
                  )),
            ),
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  constraints: BoxConstraints.tightFor(height: 50, width: 150),
                  child: ElevatedButton(
                    child: Text("Bark"),
                    onPressed: () {
                      _sendHttpBehaviorReq("bark", context);
                    },
                  )),
            ),
          ],)
        ],)
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
  bool recording = false;
  final List<User> users = [User("Asaf", "")];
  final Map<String, String> users_map = {};
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

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

  void getUsersMap() async {
    final String url = "http://$robotIP:$httpPort/download_users";
    final response =
        await http.get(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            "assets/images/logo_cropped.png",
          ),
        ),
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
          child: Text('Take video from phone'),
          onPressed: () {
            if (nameController.text != "") {
              _recordVideo();
            }
          },
        ),
        ElevatedButton(
          child: Text('Let robopet look at you'),
          onPressed: () {
            if (nameController.text != "") {
              _addUser("", "robot");
            }
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

  Future<void> _sendUserToRobot(String photoPath) async {
    final String url = "http://$robotIP:$httpPort/upload";
    var request = http.MultipartRequest('PUT', Uri.parse(url));
    request.fields['user'] = nameController.text;
    request.files.add(await http.MultipartFile.fromPath('video', photoPath));

    // Throws TimeoutException if timeout passes
    http.Response response =
        await http.Response.fromStream(await request.send());

    if (response.statusCode == 422) {
      throw OpenCVException("Record again");
    } else if (response.statusCode != 201) {
      throw Exception("File transfer to robot failed");
    }
  }

  Future<void> _recordFromRobot() async {
    final String url = "http://$robotIP:$httpPort/take_video";
    final response = await http.put(
        Uri.parse(url),
        body: { "user": nameController.text}
    );

    if (response.statusCode == 422) {
      throw OpenCVException("Robot couldn't take a good look at you");
    } else if (response.statusCode != 201) {
      throw Exception("Rquest failed");
    }
  }


  Future<void> _showAgainDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Insufficient Video'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text("Robopet failed to learn your face"),
                Text('Please try again.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addUser(String photoPath, String camera) async {
    try {
      Dialogs.showLoadingDialog(context, _keyLoader);
      if (camera == 'phone') {
        await _sendUserToRobot(photoPath);
      } else {
        await _recordFromRobot();
      }
      Navigator.of(_keyLoader.currentContext).pop();
      final snackbar = SnackBar(content: Text("Success"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on OpenCVException {
      Navigator.of(_keyLoader.currentContext).pop();
      _showAgainDialog();
    } on SocketException {
      Navigator.of(_keyLoader.currentContext).pop();
      Navigator.pop(context);
      final snackbar = SnackBar(content: Text("File transfer timed out"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on Exception catch (e) {
      Navigator.of(_keyLoader.currentContext).pop();
      Navigator.pop(context);
      final snackbar = SnackBar(content: Text("$e"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } finally {
      if (camera == 'phone') {
        Navigator.pop(context);
      }
    }
  }

  void _recordVideo() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Take video")),
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
          child: Icon(Icons.videocam),
          onPressed: () async {
            try {
              if (!recording) {
                await _initializeControllerFuture;
                await _controller.startVideoRecording();
                setState(() {
                  recording = true;
                });
              } else {
                final video = await _controller.stopVideoRecording();
                _addUser(video.path, "phone");
                setState(() {
                  recording = false;
                });
              }
            } catch (e) {
              print(e);
            }
          },
        ),
      );
    }));
  }
}

class BehaviorControl extends StatelessWidget  {
  final String title = "Behaviors";

  void _sendHttpBehaviorReq(String behvaior, BuildContext context) async {
    final String url = "http://$robotIP:$httpPort/$behvaior";
    var request = http.Request('PUT', Uri.parse(url));
    try {
      var response = await request.send();
      if (response.statusCode == 204) {
        final snackbar = SnackBar(content: Text("Behvaior request accepted: $behvaior"));
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
      else {
        throw Exception("Bad status code: ${response.statusCode}");
      }
    } on Exception catch (e) {
      final snackbar = SnackBar(content: Text("Behvaior request failed: $e"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // title: Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Image.asset(
          //     "assets/images/title.jpeg",
          //   ),
          // ),
          title: Text(title),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
            "assets/images/logo_cropped.png",
            ),
          ),
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
                      child: Text("Friendly"),
                      onPressed: () {
                       _sendHttpBehaviorReq("friendly", context);
                      },
                    )),
                Container(
                    margin: EdgeInsets.only(top: 15, bottom: 15),
                    constraints: BoxConstraints.tightFor(height: 50, width: 150),
                    child: ElevatedButton(
                      child: Text("Hostile"),
                      onPressed: () {
                        _sendHttpBehaviorReq("hostile", context);
                      },
                    )),
                Container(
                    margin: EdgeInsets.only(top: 15, bottom: 15),
                    constraints: BoxConstraints.tightFor(height: 50, width: 150),
                    child: ElevatedButton(
                      child: Text("Follow"),
                      onPressed: () {
                        _sendHttpBehaviorReq("follow", context);
                      },
                    )),
                Container(
                    margin: EdgeInsets.only(top: 15, bottom: 15),
                    constraints: BoxConstraints.tightFor(height: 50, width: 150),
                    child: ElevatedButton(
                      child: Text("Sleep"),
                      onPressed: () {
                        _sendHttpBehaviorReq("sleep", context);
                      },
                    ))
              ],
            )));
  }
}

