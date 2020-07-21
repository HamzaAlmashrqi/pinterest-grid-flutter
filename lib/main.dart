import "dart:convert";

import 'package:flutter/material.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Image List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // THE "StaggeredGridView" SCROLLCONTROLLER
  ScrollController _controller;

  // URL TO FETCH IMAGES
  final String url = "https://api.unsplash.com/photos";

  // BREAKPOINTS FOR RESPONSIBILITY
  final List<double> breakpoints = [1100, 900, 600, 300, 200];
  final List<int> breakpointsValues = [6, 4, 3, 2, 1];

  // ARRAY OF IMAGE LINKS TO RENDER IN A IMAGE WIDGET
  List<String> imagesURL = [];

  // FUNCTION TO LOAD MORE IMAGES
  Future<void> fetchImages() async {
    try {
      String clientId = DotEnv().env['UNSPLASH_ACCESS_KEY'];

      var response = await http
          .get(url, headers: {"Authorization": "Client-ID $clientId"});

      List<dynamic> images = jsonDecode(response.body);

      setState(() {
        images.forEach((imageDetails) {
          imagesURL.add(imageDetails["urls"]["regular"]);
        });
      });
    } catch (e) {
      print(e);
    }
  }

  // LISTENER OF SCROLLCONTROLLER
  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      fetchImages();
    }
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_scrollListener);

    fetchImages();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int columnsLength = 0;

    double width = MediaQuery.of(context).size.width;

    for (int i = 0; i < breakpoints.length; i++) {
      double breakpoint = breakpoints[i];

      if (width >= breakpoint) {
        columnsLength = breakpointsValues[i];
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StaggeredGridView.count(
          controller: _controller,
          crossAxisCount: columnsLength,
          children: List.generate(imagesURL.length, (int index) {
            String url = imagesURL[index];

            return _Tile(index, url);
          }),
          staggeredTiles: List.generate(imagesURL.length, (int index) {
            return StaggeredTile.fit(1);
          })),
    );
  }
}

class _Tile extends StatelessWidget {
  final int index;
  final String url;

  _Tile(this.index, this.url);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(5),
        child: Stack(children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Container(
                child: CircularProgressIndicator(),
                alignment: Alignment.center,
                height: 60),
          ),
          Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: url,
              ),
            ),
          ),
        ]));
  }
}
