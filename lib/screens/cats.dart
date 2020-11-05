import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;

class Cats extends StatefulWidget {
  @override
  _CatsState createState() => _CatsState();
}

class _CatsState extends State<Cats> with TickerProviderStateMixin {
  bool _loading;
  AnimationController _controller;

  static const List<IconData> icons = const [Icons.camera_alt, Icons.photo];

  void initState() {
    super.initState();
    _loading = true;
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/cats.tflite",
      labels: "assets/labels2.txt",
    );
  }

  File _image;
  List _outputs;
  final picker = ImagePicker();
  pickImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(File(image.path));
  }

  pickImage2() async {
    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(File(image.path));
  }

  // Classifiy the image selected
  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.1,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified class name and confidence
      _outputs = output;
      //print(_outputs);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).cardColor;
    Color foregroundColor = Theme.of(context).accentColor;
    return Scaffold(
        appBar: AppBar(
          title: Text('Cats Breed Classifier'),
          backgroundColor: Colors.pinkAccent,
        ),
        body: _loading
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image == null
                        ? Container()
                        : Image.file(_image,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 2),
                    SizedBox(
                      height: 20,
                    ),
                    _outputs != null
                        ? Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${_outputs[0]["label"]}".replaceAll(
                                          RegExp(r'[0-9]') ??
                                              "Classification failed. Please try again!",
                                          ''),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                        "Confidence: ${_outputs[0]["confidence"]}")
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Expanded(
                            child: new Stack(
                              children: <Widget>[
                                new Container(
                                  //width: MediaQuery.of(context).size.width * 0.95,
                                  height:
                                      MediaQuery.of(context).size.height * 0.8,
                                  decoration: new BoxDecoration(
                                    image: new DecorationImage(
                                      image: new AssetImage("assets/cats.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                  ],
                ),
              ),
        floatingActionButton: new Column(
          mainAxisSize: MainAxisSize.min,
          children: new List.generate(icons.length, (int index) {
            Widget child = new Container(
              height: 70.0,
              width: 56.0,
              alignment: FractionalOffset.topCenter,
              child: new ScaleTransition(
                scale: new CurvedAnimation(
                  parent: _controller,
                  curve: new Interval(0.0, 1.0 - index / icons.length / 2.0,
                      curve: Curves.easeOut),
                ),
                child: new FloatingActionButton(
                  heroTag: null,
                  backgroundColor: backgroundColor,
                  mini: true,
                  child: new Icon(icons[index], color: foregroundColor),
                  onPressed: () {
                    if (index == 1)
                      pickImage();
                    else
                      pickImage2();
                  },
                ),
              ),
            );
            return child;
          }).toList()
            ..add(
              new FloatingActionButton(
                heroTag: null,
                child: new AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget child) {
                    return new Transform(
                      transform: new Matrix4.rotationZ(
                          _controller.value * 0.5 * math.pi),
                      alignment: FractionalOffset.center,
                      child: new Icon(
                          _controller.isDismissed ? Icons.add : Icons.close),
                    );
                  },
                ),
                onPressed: () {
                  if (_controller.isDismissed) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
              ),
            ),
        ));
  }
}
