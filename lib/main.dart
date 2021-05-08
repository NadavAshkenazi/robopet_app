import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:control_pad/control_pad.dart';
import 'package:flutter/material.dart';

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
  final CameraDescription camera;

  UsersPage({Key key, @required this.camera}) : super(key: key);
  final String title = "Users";

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

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
      body: Center(
        child: Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addUser();
        },
        tooltip: 'Add user',
        child: Icon(Icons.add),
      ),
    );
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

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DisplayPictureScreen(
                            imagePath: image?.path,
                          )));
            } catch (e) {
              print(e);
            }
          },
        ),
      );
    }));
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
