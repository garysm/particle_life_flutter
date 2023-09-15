import 'package:flutter/material.dart';
import "package:p5/p5.dart";
import 'package:url_launcher/url_launcher_string.dart';

import 'matrix_sketch.dart';
import "particle_sketch.dart";

ParticleSketch sketch = ParticleSketch();

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Life',
      theme: ThemeData(
//        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
      ),
      home: const MyHomePage(),
    );
  }
}

VoidCallback? _loopCallback;

class ParticleScreen extends StatefulWidget {
  const ParticleScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ParticleScreenState();
}

class _ParticleScreenState extends State<ParticleScreen>
    with SingleTickerProviderStateMixin {
  late PAnimator animator;

  @override
  void initState() {
    super.initState();

    animator = PAnimator(this);
    animator.addListener(() {
      setState(() {
        sketch.redraw();
      });

      if (_loopCallback != null) {
        _loopCallback!();
      }
    });
    animator.run();
  }

  @override
  Widget build(BuildContext context) {
    return PWidget(sketch);
  }
}

class PauseButton extends StatefulWidget {
  final VoidCallback _callback;
  const PauseButton(this._callback, {Key? key}) : super(key: key);

  @override
  State createState() {
    return PauseButtonState(_callback);
  }
}

class PauseButtonState extends State<PauseButton> {
  final VoidCallback _callback;
  PauseButtonState(this._callback);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Pause / Resume",
      icon: sketch.paused
          ? const Icon(Icons.play_arrow)
          : const Icon(Icons.pause),
      onPressed: () {
        setState(() {
          sketch.paused ^= true;
        });
        _callback();
      },
    );
  }
}

class InfoText extends StatefulWidget {
  const InfoText({Key? key}) : super(key: key);

  @override
  State createState() => _InfoTextState();
}

class _InfoTextState extends State<InfoText> {
  num _fps = 0;

  @override
  void initState() {
    super.initState();

    _loopCallback = () {
      if (mounted) {
        setState(() {
          _fps = sketch.fps;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(color: Colors.white.withOpacity(0.2));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        "FPS: ${_fps.round()}",
        style: textStyle,
      ),
    );
  }
}

class MatrixSizeSlider extends StatefulWidget {
  const MatrixSizeSlider({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MatrixSizeSliderState();
}

class _MatrixSizeSliderState extends State<MatrixSizeSlider> {
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: sketch.world!.matrix!.n.toDouble(),
      label: "${sketch.world!.matrix!.n}",
      min: 1.0,
      max: 17.0,
      divisions: 17,
      onChanged: (double val) {
        setState(() {
          sketch.world!.requestMatrixSize(val.round());
        });
      },
    );
  }
}

class SpawnModeDropdown extends StatefulWidget {
  const SpawnModeDropdown({Key? key}) : super(key: key);

  @override
  State createState() => _SpawnModeDropdownState();
}

class _SpawnModeDropdownState extends State<SpawnModeDropdown> {
  List<String?> spawnModes = [
    "Uniform",
    "Sphere",
    "Centered Sphere",
    "Circle",
    "Spiral"
  ];
  List<DropdownMenuItem>? items;

  @override
  void initState() {
    super.initState();

    items = spawnModes.map<DropdownMenuItem<String>>((String? value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value!),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: spawnModes[sketch.world!.spawnMode],
      icon: const Icon(Icons.arrow_drop_down),
      onChanged: (String? selected) {
        setState(() {
          int index = spawnModes.indexOf(selected);
          if (index != -1) {
            sketch.world!.spawnMode = index;
          }
        });
      },
      items: items as List<DropdownMenuItem<String>>?,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _keyScaffold = GlobalKey<ScaffoldState>();

  var spawnMode = "Uniform";

  @override
  Widget build(BuildContext context) {
    List<Widget> actionButtons = <Widget>[
      IconButton(
        tooltip: "Edit Matrix",
        icon: const Icon(Icons.apps),
        onPressed: () {
          _openMatrixDialog(context);
        },
      ),
      IconButton(
        tooltip: "New Rules",
        icon: const Icon(Icons.shuffle),
        onPressed: () {
          sketch.world!.requestReset();
        },
      ),
      IconButton(
        tooltip: "Stir Up",
        icon: const Icon(Icons.refresh),
        onPressed: () {
          sketch.world!.requestRespawn();
        },
      ),
      PauseButton(() {
        setState(() {});
      }),
    ];

    return Scaffold(
      key: _keyScaffold,
      appBar: AppBar(
        title: const Text("Particle Life"),
        actions: actionButtons,
      ),
      backgroundColor: const Color.fromRGBO(0, 0, 0, 1.0),
      body: const Center(
        child: ParticleScreen(),
      ),
      drawer: MyDrawer(actionButtons),
    );
  }
}

class MyDrawer extends StatefulWidget {
  final List<Widget> actionButtons;

  const MyDrawer(this.actionButtons, {Key? key}) : super(key: key);

  @override
  State createState() => _MyDrawerState(actionButtons);
}

class _MyDrawerState extends State<MyDrawer> {
  final List<Widget> actionButtons;

  _MyDrawerState(this.actionButtons);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      ),
      child: Drawer(
          child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            Center(
                child: ButtonBar(
              alignment: MainAxisAlignment.center,
              children: actionButtons,
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const <Widget>[
                Text("Colors"),
                MatrixSizeSlider(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("min Radius"),
                Slider(
                  value: sketch.world!.rMin.toDouble(),
                  min: 10,
                  max: 100,
                  onChanged: (double val) {
                    if (val <= sketch.world!.requestedRMax!) {
                      setState(() {
                        sketch.world!.rMin = val.toInt();
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("max Radius"),
                Slider(
                  value: sketch.world!.requestedRMax!.toDouble(),
                  min: 10,
                  max: 100,
                  onChanged: (double val) {
                    if (val >= sketch.world!.rMin) {
                      setState(() {
                        sketch.world!.requestNewRMax(val.toInt());
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Friction"),
                Slider(
                    value: sketch.world!.friction,
                    label: "${sketch.world!.friction}",
                    min: 0,
                    max: 20,
                    onChanged: (double val) {
                      setState(() {
                        sketch.world!.friction = val;
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Heat"),
                Slider(
                    value: sketch.world!.heat,
                    label: "${sketch.world!.heat}",
                    min: 0,
                    max: 100,
                    onChanged: (double val) {
                      setState(() {
                        sketch.world!.heat = val;
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Force Factor"),
                Slider(
                    value: sketch.world!.forceFactor,
                    label: "${sketch.world!.forceFactor}",
                    min: 0,
                    max: 1500,
                    onChanged: (double val) {
                      setState(() {
                        sketch.world!.forceFactor = val;
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Particles: ${sketch.world!.calcParticleCount()}"),
                Slider(
                    value: sketch.world!.requestedParticleDensity!,
                    min: 0.0,
                    max: 0.005,
                    onChanged: (double val) {
                      setState(() {
                        sketch.world!.requestParticleDensity(val);
                      });
                    }),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const <Widget>[
                Text("Spawn Mode"),
                SpawnModeDropdown(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Particle Size"),
                Slider(
                  value: sketch.world!.particleSize.toDouble(),
                  label: "${sketch.world!.particleSize.toInt()} Px.",
                  min: 1,
                  max: 4,
                  onChanged: (double val) {
                    setState(() {
                      sketch.world!.particleSize = val.toInt();
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Wrap World"),
                Switch(
                  value: sketch.world!.wrapWorld,
                  onChanged: (bool val) {
                    setState(() {
                      sketch.world!.wrapWorld = val;
                    });
                  },
                ),
              ],
            ),
            const InfoText(),
            Center(
              child: OutlinedButton(
                child: const Text("about"),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: "Particle Life",
                    applicationIcon: const Icon(Icons.brightness_1),
                    children: <Widget>[
                      const Text(
                          "This is an optimized version of Jeffrey Ventrella's \"Clusters\".\n\n"
                          "For documentation, source code and a similar "
                          "(but faster) Java program, go to github.com/quarfzs/particle-life:"),
                      ButtonBar(
                        children: <Widget>[
                          OutlinedButton.icon(
                            icon: const Icon(Icons.code),
                            label: const Text("GitHub"),
                            onPressed: () {
                              _launchURL(
                                  "https://github.com/quarfzs/particle-life");
                            },
                          ),
                          OutlinedButton(
                            child: const Text("Jeffrey Ventrella"),
                            onPressed: () {
                              _launchURL("http://www.ventrella.com/Clusters/");
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      )),
    );
  }
}

_launchURL(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    throw "Could not launch $url";
  }
}

_openMatrixDialog(BuildContext context) {
  Dialog dialog = Dialog(
    backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
    child: const MatrixController(),
  );
  showDialog(context: context, builder: (BuildContext context) => dialog);
}

class MatrixController extends StatefulWidget {
  const MatrixController({Key? key}) : super(key: key);

  @override
  State createState() => _MatrixControllerState();
}

class _MatrixControllerState extends State<MatrixController> {
  bool _active = false;
  int? _i;
  int? _j;

  void selectionChanged(bool active, int i, int j) {
    setState(() {
      _active = active;
      _i = i;
      _j = j;
    });
  }

  @override
  Widget build(BuildContext context) {
    Slider slider = Slider(
      value: _active ? sketch.world!.matrix!.get(_i!, _j)! : 0,
      label: _active
          ? "${(sketch.world!.matrix!.get(_i!, _j)! * 10).round()}"
          : "",
      min: -1.0,
      max: 1.0,
      divisions: 20,
      onChanged: !_active
          ? null
          : (double value) {
              if (_active) {
                setState(() {
                  sketch.world!.matrix!.set(_i!, _j, value);
                });
              }
            },
      inactiveColor: Colors.grey,
    );

    PWidget matrixWidget = PWidget(MatrixSketch(
      sketch.world!.matrix,
      active: _active,
      i: _i,
      j: _j,
      selectionCallback: (bool active, int? i, int? j) {
        setState(() {
          _active = active;
          _i = i;
          _j = j;
        });
      },
    ));

    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Matrix"),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: matrixWidget,
          ),
          slider,
          //Padding(padding: EdgeInsets.only(top: 50.0)),
          TextButton(
            child: const Text("close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
