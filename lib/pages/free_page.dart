import 'dart:math';

import 'package:anoter/models/drop_models.dart';
import 'package:anoter/sl.dart';
import 'package:anoter/utils/curves.dart';
import 'package:anoter/utils/local_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:provider/provider.dart';
import 'package:pwa_install/pwa_install.dart';

const double MINIMUN_WIDTH = 80;

class InfoProvider with ChangeNotifier {
  List<String> treeName;
  final String id;
  InfoProvider(this.id, this.treeName);
}

class FreePage extends StatelessWidget {
  const FreePage(this.treeName, this.id, {super.key});
  final List<String> treeName;
  final String id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl.get<LocalRepository>().getDropPage(id),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasData) {
          if (asyncSnapshot.data != null) {
            if (PWAInstall().installPromptEnabled) {
              PWAInstall().promptInstall_();
            }
            return ChangeNotifierProvider(
              create: (_) => InfoProvider(id, treeName),
              child: FreePageWidget(
                asyncSnapshot.data!.dropModels,
                asyncSnapshot.data!.dropOrder,
                false,
                id,
              ),
            );
          }
        }
        return FreePageWidget({}, [], true, id);
      },
    );
  }
}

class FreePageWidget extends StatefulWidget {
  const FreePageWidget(
    this.models,
    this.modelIds,
    this.isLoading,
    this.id, {
    super.key,
  });
  final bool isLoading;
  final Map<String, DropModel> models;
  final List<String> modelIds;
  final String id;

  @override
  State<FreePageWidget> createState() => _FreePageWidgetState();
}

class _FreePageWidgetState extends State<FreePageWidget> {
  bool saved = false;

  @override
  void dispose() async {
    if (widget.isLoading == false) {
      if (widget.modelIds.isNotEmpty && widget.models.entries.isNotEmpty) {
        await saveData();
      }
    }
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> saveData() async {
    await sl.get<LocalRepository>().saveDropPage(
      widget.id,
      DropPage(dropModels: widget.models, dropOrder: widget.modelIds),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white70),
              flexibleSpace: Row(
                children: [
                  Expanded(child: Container()),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: saved
                        ? Colors.green.shade300
                        : Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Sync',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 32),
                  FilledButton(
                    onPressed: saved
                        ? null
                        : () {
                            saveData();
                            /*.then((value) {
                                  if (mounted) {
                                    setState(() {
                                      saved = true;
                                    });
                                  }
                                });*/
                          },
                    child: Text('Save'),
                  ),
                  SizedBox(width: 16),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            body: SizedBox(
              height: double.infinity,
              child: FreePageContainer(widget.models, widget.modelIds),
            ),
          ),
          if (widget.isLoading) ModalBarrier(color: Colors.grey.withAlpha(60)),
          if (widget.isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class ArrowMenuItem extends StatelessWidget {
  ArrowMenuItem(
    this.stackKey,
    this.modelIds,
    this.models,
    this.refresh,
    this.coefficentOfResizing, {
    super.key,
  });
  final GlobalKey stackKey;
  final ArrowDropModel model = ArrowDropModel(x1: -100, y1: -100);
  final List<String> modelIds;
  final Offset coefficentOfResizing;
  final Function() refresh;
  final Map<String, DropModel> models;

  @override
  Widget build(BuildContext context) {
    return Draggable(
      onDragStarted: () {
        models[model.id] = model;
      },
      onDragEnd: (details) {
        final renderBox =
            stackKey.currentContext!.findRenderObject() as RenderBox;
        final vector =
            renderBox.globalToLocal(details.offset) - coefficentOfResizing;
        model.x = vector.dx;
        model.y = vector.dy;
        model.x1 = vector.dx + 100;
        model.y1 = vector.dy + 100;
        modelIds.remove(model.id);
        modelIds.add(model.id);
        refresh();
      },
      feedback: ArrowModelWidget(
        model,
        FocusNode(),
        coefficentOfResizing,
        stackKey,
        refresh,
        {},
        () {},
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getArrowIcon(context),
          Text(
            "Arrow",
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container getArrowIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      width: 32,
      height: 32,
      child: CustomPaint(
        size: Size(32, 32),
        painter: ArrowModelPainter(Offset(4, 4), Offset(24, 24)),
      ),
    );
  }
}

class NoteMenuItem extends StatelessWidget {
  NoteMenuItem(
    this.stackKey,
    this.modelIds,
    this.models,
    this.refresh,
    this.coefficentOfResizing, {
    super.key,
  });
  final GlobalKey stackKey;
  final SimpleNoteDropModel model = SimpleNoteDropModel(text: '')..width = 120;
  final List<String> modelIds;
  final Offset coefficentOfResizing;
  final Function() refresh;
  final Map<String, DropModel> models;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: model.id,
      onDragStarted: () {
        models[model.id] = model;
      },
      onDragEnd: (details) {
        final renderBox =
            stackKey.currentContext!.findRenderObject() as RenderBox;
        final vector =
            renderBox.globalToLocal(details.offset) - coefficentOfResizing;
        model.x = vector.dx;
        model.y = vector.dy;
        modelIds.remove(model.id);
        modelIds.add(model.id);
        refresh();
      },
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                offset: Offset(4, 4),
                blurRadius: 4,
                color: Theme.of(context).colorScheme.shadow.withAlpha(120),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          width: model.width,
          child: modulator(model, context),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getNoteIcon(context),
          Text(
            "Note",
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container getNoteIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            LinearProgressIndicator(
              value: 1,
              borderRadius: BorderRadius.circular(8),
              minHeight: 4,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            LinearProgressIndicator(
              value: 1,
              borderRadius: BorderRadius.circular(8),
              minHeight: 4,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            LinearProgressIndicator(
              value: 0.7,
              borderRadius: BorderRadius.circular(8),
              minHeight: 4,
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class ImageMenuItem extends StatelessWidget {
  ImageMenuItem(
    this.stackKey,
    this.modelIds,
    this.models,
    this.refresh,
    this.coefficentOfResizing, {
    super.key,
  });
  final GlobalKey stackKey;
  final ImageDropModel model = ImageDropModel(title: '', image: Uint8List(0))
    ..width = 240;
  final List<String> modelIds;
  final Offset coefficentOfResizing;
  final Function() refresh;
  final Map<String, DropModel> models;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final data = await ImagePickerWeb.getImageAsBytes();
        if (data != null) {
          final screenSize = MediaQuery.of(context).size;
          final offset =
              (stackKey.currentContext!.findRenderObject() as RenderBox)
                  .globalToLocal(
                    Offset(screenSize.width / 2, screenSize.height / 2),
                  ) -
              coefficentOfResizing;

          model.x = offset.dx;
          model.y = offset.dy;
          model.image = data;
          models[model.id] = model;
          modelIds.add(model.id);
          refresh();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getImageIcon(context),
          Text(
            "Image",
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container getImageIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              height: 20,
              width: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Colors.blue,
                      0.2,
                    )!,
                    Color.lerp(
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                      Colors.red,
                      0.2,
                    )!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}

Color getRandomVibrantColor() {
  final List<Color> vibrantColors = [
    Colors.red.shade300,
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.yellow.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
    Colors.pink.shade300,
    Colors.cyan.shade300,
    Colors.teal.shade300,
    Colors.amber.shade300,
  ];

  return vibrantColors[Random().nextInt(vibrantColors.length)];
}

class PageMenuItem extends StatelessWidget {
  PageMenuItem(
    this.stackKey,
    this.modelIds,
    this.models,
    this.refresh,
    this.coefficentOfResizing, {
    super.key,
  });
  final GlobalKey stackKey;
  final PageDropModel model = PageDropModel(
    color: getRandomVibrantColor(),
    title: '',
  );
  final List<String> modelIds;
  final Offset coefficentOfResizing;
  final Function() refresh;
  final Map<String, DropModel> models;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: model.id,
      onDragEnd: (details) {
        final renderBox =
            stackKey.currentContext!.findRenderObject() as RenderBox;
        final vector =
            renderBox.globalToLocal(details.offset) - coefficentOfResizing;
        model.x = vector.dx;
        model.y = vector.dy;
        models[model.id] = model;
        modelIds.remove(model.id);
        modelIds.add(model.id);
        refresh();
      },
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                offset: Offset(4, 4),
                blurRadius: 4,
                color: Theme.of(context).colorScheme.shadow.withAlpha(120),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: PageModelWidget(model),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: pageIcon(Colors.red, context, 0.6),
          ),
          Text(
            "Page",
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container getPageIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: pageIcon(model.color, context, 0.5),
      ),
    );
  }
}

class ColumnMenuItem extends StatelessWidget {
  ColumnMenuItem(
    this.stackKey,
    this.modelIds,
    this.models,
    this.refresh,
    this.coefficentOfResizing,
    this.controller, {
    super.key,
  });
  final GlobalKey stackKey;
  final ColumnDropModel model = ColumnDropModel(title: '');
  final List<String> modelIds;
  final Offset coefficentOfResizing;
  final Function() refresh;
  final Map<String, DropModel> models;
  final TransformationController controller;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: model.id,
      onDragEnd: (details) {
        final renderBox =
            stackKey.currentContext!.findRenderObject() as RenderBox;
        final vector =
            renderBox.globalToLocal(details.offset) - coefficentOfResizing;
        model.x = vector.dx;
        model.y = vector.dy;
        models[model.id] = model;
        modelIds.remove(model.id);
        modelIds.add(model.id);
        refresh();
      },
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                offset: Offset(4, 4),
                blurRadius: 4,
                color: Theme.of(context).colorScheme.shadow.withAlpha(120),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: ColumnWidget(
            model,
            models,
            modelIds,
            refresh,
            stackKey,
            controller,
            coefficentOfResizing,
            {},
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getColumnIcon(context),
          Text(
            "Column",
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container getColumnIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              height: 8,
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}

class FreePageContainer extends StatefulWidget {
  const FreePageContainer(this.models, this.modelIds, {super.key});
  final Map<String, DropModel> models;
  final List<String> modelIds;

  @override
  State<FreePageContainer> createState() => _FreePageContainerState();
}

class _FreePageContainerState extends State<FreePageContainer> {
  //late Map<String, DropModel> models;
  Map<String, GlobalKey> modelKeys = {};
  Map<String, FocusNode> modelFocuses = {};
  //late List<String> modelIds;
  final GlobalKey key = GlobalKey();
  late Widget verticalScroller;
  late Widget horizontalScroller;
  final verticalKey = GlobalKey<_ViewScrollerState>();
  final horizontalKey = GlobalKey<_ViewScrollerState>();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    //widget.models = widget.models;
    //modelIds = widget.modelIds;
    verticalScroller = ViewScroller(Axis.vertical, key: verticalKey);
    horizontalScroller = ViewScroller(Axis.horizontal, key: horizontalKey);
    controller.addListener(rebuildScrollers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    FocusManager.instance.addListener(() {
      if (modelFocuses.values.any((focus) => focus.hasPrimaryFocus)) {
        setState(() {});
      }
    });
    maximumWidth = widget.models.values.fold(
      widget.models.isEmpty ? 0 : widget.models.values.first.x,
      maxiWidth,
    );
    minimumWidth = widget.models.values.fold(
      widget.models.isEmpty ? 0 : widget.models.values.first.x,
      miniWidth,
    );
    maximumHeight = widget.models.values.fold(
      widget.models.isEmpty ? 0 : widget.models.values.first.y,
      maxiHeight,
    );
    minimumHeight = widget.models.values.fold(
      widget.models.isEmpty ? 0 : widget.models.values.first.y,
      miniHeight,
    );
    super.initState();
  }

  FocusNode getFocusNode(String id) {
    if (!modelFocuses.containsKey(id)) {
      modelFocuses[id] = FocusNode();
    }
    return modelFocuses[id]!;
  }

  GlobalKey getKey(String id) {
    if (!modelKeys.containsKey(id)) {
      modelKeys[id] = GlobalKey();
    }
    return modelKeys[id]!;
  }

  void rebuildScrollers() {
    final mainer = MediaQuery.of(context).size;
    final translationVector = controller.value.getTranslation();
    verticalKey.currentState?.setData(
      max: sizer.dy,
      size: mainer.height,
      offset:
          sizer.dy -
          mainer.height -
          max(
            min(translationVector.y + viewPort.dy, sizer.dy - mainer.height),
            0,
          ),
    );
    horizontalKey.currentState?.setData(
      max: sizer.dx,
      size: mainer.width,
      offset:
          sizer.dx -
          mainer.width -
          max(
            min(translationVector.x + viewPort.dx, sizer.dx - mainer.width),
            0,
          ),
    );
  }

  TransformationController controller = TransformationController();
  Offset viewPort = Offset(0, 0);
  Offset sizer = Offset(0, 0);

  void translateInteractiveView(List<double> translator) {
    Matrix4 tempMatrix = Matrix4.identity();
    controller.value.copyInto(tempMatrix);
    controller.value = tempMatrix..translate(translator[0], translator[1], 0);
  }

  double miniWidth(double value, DropModel model) {
    if (model is ArrowDropModel) {
      return min(min(model.x1, model.x), value);
    }
    return min(model.x, value);
  }

  double maxiWidth(double value, DropModel model) {
    if (model is ArrowDropModel) {
      return max(max(model.x1, model.x), value);
    } else if (model is DropContentModel) {
      if (modelKeys.containsKey(model.id)) {
        final context = modelKeys[model.id]!.currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox;
          if (renderBox.hasSize) {
            return max(model.x + renderBox.size.width, value);
          }
        }
      }
    }
    return max(model.x, value);
  }

  double miniHeight(double value, DropModel model) {
    if (model is ArrowDropModel) {
      return min(min(model.y1, model.y), value);
    }
    return min(model.y, value);
  }

  double maxiHeight(double value, DropModel model) {
    if (model is ArrowDropModel) {
      return max(max(model.y1, model.y), value);
    } else if (model is DropContentModel) {
      if (modelKeys.containsKey(model.id)) {
        final context = modelKeys[model.id]!.currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox;
          if (renderBox.hasSize) {
            return max(model.x + renderBox.size.height, value);
          }
        }
      }
    }
    return max(model.y, value);
  }

  void removeModel(String id) {
    widget.models.remove(id);
    widget.modelIds.remove(id);
    modelFocuses.remove(id);
    modelKeys.remove(id);
    setState(() {});
  }

  double maximumWidth = 0;
  double minimumWidth = 0;
  double maximumHeight = 0;
  double minimumHeight = 0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      double new_maximumWidth = widget.models.values.fold(
        widget.models.isEmpty ? 0 : widget.models.values.first.x,
        maxiWidth,
      );
      double new_minimumWidth = widget.models.values.fold(
        widget.models.isEmpty ? 0 : widget.models.values.first.x,
        miniWidth,
      );
      double new_maximumHeight = widget.models.values.fold(
        widget.models.isEmpty ? 0 : widget.models.values.first.y,
        maxiHeight,
      );
      double new_minimumHeight = widget.models.values.fold(
        widget.models.isEmpty ? 0 : widget.models.values.first.y,
        miniHeight,
      );
      if (new_minimumHeight != minimumHeight ||
          new_maximumHeight != maximumHeight ||
          new_minimumWidth != minimumWidth ||
          new_maximumWidth != maximumWidth) {
        setState(() {
          minimumHeight = new_minimumHeight;
          maximumHeight = new_maximumHeight;
          minimumWidth = new_minimumWidth;
          maximumWidth = new_maximumWidth;
        });
      }
    });
    double width =
        maximumWidth - minimumWidth + 2 * MediaQuery.of(context).size.width;
    double height =
        maximumHeight -
        minimumHeight +
        1.4 * MediaQuery.of(context).size.height;

    Offset coefficentOfResizing = Offset(
      -minimumWidth + 0.7 * MediaQuery.of(context).size.width,
      -minimumHeight + 0.7 * MediaQuery.of(context).size.height,
    );

    sizer = Offset(width, height);

    controller.value.translate(
      viewPort.dx - coefficentOfResizing.dx,
      viewPort.dy - coefficentOfResizing.dy,
      0,
    );
    viewPort = coefficentOfResizing;
    rebuildScrollers();

    final modelKeys = Map.fromEntries(
      widget.modelIds
          .where((id) => widget.models[id] is DropContentModel)
          .map((e) => MapEntry(e, getKey(e))),
    );
    //print(context.size);
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
        setState(() {});
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (value) {
          if (FocusManager.instance.primaryFocus != _focusNode) {
            return;
          }
          if (value.logicalKey == LogicalKeyboardKey.arrowLeft) {
            translateInteractiveView([30, 0]);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowRight) {
            translateInteractiveView([-30, 0]);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
            translateInteractiveView([0, 30]);
          } else if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
            translateInteractiveView([0, -30]);
          } else if (value.logicalKey == LogicalKeyboardKey.keyZ) {
            if (value is KeyDownEvent) {
              setState(() {
                Matrix4 tempMatrix = Matrix4.identity();
                controller.value.copyInto(tempMatrix);
                controller.value = tempMatrix..scale(0.9, 0.9, 1);
              });
            }
          } else if (value.logicalKey == LogicalKeyboardKey.keyC) {
            if (value is KeyDownEvent) {
              setState(() {
                Matrix4 tempMatrix = Matrix4.identity();
                controller.value.copyInto(tempMatrix);
                controller.value = tempMatrix..scale(1.1, 1.1, 1);
              });
            }
          }
        },

        child: Row(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              width: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  NoteMenuItem(
                    key,
                    widget.modelIds,
                    widget.models,
                    () => setState(() {}),
                    coefficentOfResizing,
                  ),
                  ColumnMenuItem(
                    key,
                    widget.modelIds,
                    widget.models,
                    () => setState(() {}),
                    coefficentOfResizing,
                    controller,
                  ),
                  ArrowMenuItem(
                    key,
                    widget.modelIds,
                    widget.models,
                    () => setState(() {}),
                    coefficentOfResizing,
                  ),
                  ImageMenuItem(
                    key,
                    widget.modelIds,
                    widget.models,
                    () => setState(() {}),
                    coefficentOfResizing,
                  ),
                  PageMenuItem(
                    key,
                    widget.modelIds,
                    widget.models,
                    () => setState(() {}),
                    coefficentOfResizing,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: controller,
                    constrained: false,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        key: key,
                        children: [
                          for (final modelId
                              in widget.modelIds
                                  .where(
                                    (id) => widget.models[id] is ArrowDropModel,
                                  )
                                  .where((id) => !getFocusNode(id).hasFocus))
                            ArrowModelWidget(
                              widget.models[modelId] as ArrowDropModel,
                              getFocusNode(modelId),
                              coefficentOfResizing,
                              key,
                              () => setState(() {}),
                              modelKeys,
                              () => removeModel(modelId),
                            ),
                          for (final modelId
                              in widget.modelIds
                                  .where(
                                    (id) =>
                                        widget.models[id] is DropContentModel,
                                  )
                                  .where(
                                    (id) => widget.models.containsKey(id)
                                        ? (widget.models[id] is DropContentModel
                                              ? ((widget.models[id]
                                                                as DropContentModel)
                                                            .parentId ==
                                                        null
                                                    ? true
                                                    : false)
                                              : true)
                                        : false,
                                  ))
                            Modular(
                              widget.models[modelId] as DropContentModel,
                              false,
                              widget.modelIds,
                              () => setState(() {}),
                              controller,
                              key,
                              coefficentOfResizing,
                              widget.models,
                              getFocusNode(modelId),
                              modelKeys,
                              key: getKey(modelId),
                            ),
                          for (final modelId
                              in widget.modelIds
                                  .where(
                                    (id) => widget.models[id] is ArrowDropModel,
                                  )
                                  .where((id) => getFocusNode(id).hasFocus))
                            ArrowModelWidget(
                              widget.models[modelId] as ArrowDropModel,
                              getFocusNode(modelId),
                              coefficentOfResizing,
                              key,
                              () => setState(() {}),
                              modelKeys,
                              () => removeModel(modelId),
                            ),
                        ],
                      ),
                    ),
                  ),
                  verticalScroller,
                  horizontalScroller,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuadraticCurve {
  Offset c0;
  Offset c2;
  QuadraticCurve({required this.c0, required this.c2});
}

class ArrowModelWidget extends StatelessWidget {
  ArrowModelWidget(
    this.model,
    this.node,
    this.coefficentOfResizing,
    this.stackKey,
    this.refresh,
    this.modelKeys,
    this.removeModel, {
    super.key,
  }) : curve = ValueNotifier(
         QuadraticCurve(
           c2: Offset(model.x1, model.y1),
           c0: Offset(model.x, model.y),
         ),
       );
  final ArrowDropModel model;
  final Function() removeModel;
  final FocusNode node;
  final Map<String, GlobalKey> modelKeys;
  final Offset coefficentOfResizing;
  final ValueNotifier<QuadraticCurve> curve;
  final GlobalKey stackKey;
  final Function() refresh;

  double abs(double x) {
    if (x < 0) {
      return -x;
    }
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: curve,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          if (model.toModelId != null) {
            if (modelKeys.containsKey(model.toModelId)) {
              final renderBox =
                  modelKeys[model.toModelId]!.currentContext!.findRenderObject()
                      as RenderBox;
              Offset c2 =
                  (stackKey.currentContext!.findRenderObject() as RenderBox)
                      .globalToLocal(renderBox.localToGlobal(Offset.zero)) -
                  coefficentOfResizing +
                  Offset(renderBox.size.width / 2, renderBox.size.height / 2);
              if ((value.c2 - c2).distance > 0.001) {
                curve.value = QuadraticCurve(c0: curve.value.c0, c2: c2);
                model.x1 = c2.dx;
                model.y1 = c2.dy;
              }
            }
          }
          if (model.fromModelId != null) {
            if (modelKeys.containsKey(model.fromModelId)) {
              final renderBox =
                  modelKeys[model.fromModelId]!.currentContext!
                          .findRenderObject()
                      as RenderBox;
              Offset c0 =
                  (stackKey.currentContext!.findRenderObject() as RenderBox)
                      .globalToLocal(renderBox.localToGlobal(Offset.zero)) -
                  coefficentOfResizing +
                  Offset(renderBox.size.width / 2, renderBox.size.height / 2);
              if ((value.c0 - c0).distance > 0.001) {
                curve.value = QuadraticCurve(c0: c0, c2: curve.value.c2);
                model.x = c0.dx;
                model.y = c0.dy;
              }
            }
          }
        });
        /*if (model.toModelId != null) {
          if (modelKeys.containsKey(model.toModelId)) {
            final renderBox =
                modelKeys[model.toModelId]!.currentContext!.findRenderObject()
                    as RenderBox;
            Offset c2 =
                (stackKey.currentContext!.findRenderObject() as RenderBox)
                    .globalToLocal(renderBox.localToGlobal(Offset.zero)) -
                coefficentOfResizing +
                Offset(renderBox.size.width / 2, renderBox.size.height / 2);
            if ((value.c2 - c2).distance > 0.001) {
              curve.value = QuadraticCurve(c0: curve.value.c0, c2: c2);
            }
          }
        }*/
        /*if (model.toModelId != null) {
          if (modelKeys.containsKey(model.toModelId)) {
            final renderBox =
                modelKeys[model.toModelId]!.currentContext!.findRenderObject()
                    as RenderBox;
            c2 =
                (stackKey.currentContext!.findRenderObject() as RenderBox)
                    .globalToLocal(renderBox.localToGlobal(Offset.zero)) -
                coefficentOfResizing;
            print("C2: $c2");
          }
        }*/
        final minimized = Offset(
          min(curve.value.c0.dx - 10, curve.value.c2.dx - 10),
          min(curve.value.c0.dy - 10, curve.value.c2.dy - 10),
        );
        final maximized = Offset(
          max(curve.value.c0.dx + 10, curve.value.c2.dx + 10),
          max(curve.value.c0.dy + 10, curve.value.c2.dy + 10),
        );

        final painter = ArrowModelPainter(
          curve.value.c0 - minimized,
          curve.value.c2 - minimized,
        );
        return Positioned(
          top: minimized.dy + coefficentOfResizing.dy,
          left: minimized.dx + coefficentOfResizing.dx,
          child: Focus(
            focusNode: node,
            descendantsAreFocusable: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace ||
                    event.logicalKey == LogicalKeyboardKey.delete) {
                  removeModel();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: SizedBox(
              width: maximized.dx - minimized.dx,
              height: maximized.dy - minimized.dy,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      node.requestFocus();
                    },
                    child: CustomPaint(
                      size: Size(
                        maximized.dx - minimized.dx,
                        maximized.dy - minimized.dy,
                      ),
                      painter: painter,
                    ),
                  ),
                  if (node.hasFocus)
                    Positioned(
                      top: curve.value.c2.dy - minimized.dy - 10,
                      left: curve.value.c2.dx - minimized.dx - 10,
                      child: Draggable(
                        onDragStarted: () {
                          model.toModelId = null;
                        },
                        onDragEnd: (details) {
                          model.x1 = curve.value.c2.dx;
                          model.y1 = curve.value.c2.dy;
                          for (final key in modelKeys.entries) {
                            final renderBox =
                                key.value.currentContext!.findRenderObject()
                                    as RenderBox;
                            final point = renderBox.globalToLocal(
                              details.offset,
                            );
                            if (point.dx > 0 && point.dy > 0) {
                              if (renderBox.size.width > point.dx &&
                                  renderBox.size.height > point.dy) {
                                model.toModelId = key.key;
                                refresh();
                                return;
                              }
                            }
                          }
                        },
                        onDragUpdate: (details) {
                          curve.value.c2 += details.delta;
                          curve.value = QuadraticCurve(
                            c0: curve.value.c0,
                            c2: curve.value.c2,
                          );
                        },
                        childWhenDragging: SizedBox(),
                        feedback: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.black.withAlpha(140),
                        ),
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.black.withAlpha(140),
                        ),
                      ),
                    ),
                  if (node.hasFocus)
                    Positioned(
                      top: curve.value.c0.dy - minimized.dy - 10,
                      left: curve.value.c0.dx - minimized.dx - 10,
                      child: Draggable(
                        onDragStarted: () {
                          model.fromModelId = null;
                        },
                        onDragEnd: (details) {
                          model.x = curve.value.c0.dx;
                          model.y = curve.value.c0.dy;
                          for (final key in modelKeys.entries) {
                            final renderBox =
                                key.value.currentContext!.findRenderObject()
                                    as RenderBox;
                            final point = renderBox.globalToLocal(
                              details.offset,
                            );
                            if (point.dx > 0 && point.dy > 0) {
                              if (renderBox.size.width > point.dx &&
                                  renderBox.size.height > point.dy) {
                                model.fromModelId = key.key;
                                refresh();
                                return;
                              }
                            }
                          }
                        },
                        onDragUpdate: (details) {
                          curve.value.c0 += details.delta;
                          curve.value = QuadraticCurve(
                            c0: curve.value.c0,
                            c2: curve.value.c2,
                          );
                        },
                        childWhenDragging: SizedBox(),
                        feedback: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.black.withAlpha(140),
                        ),
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.black.withAlpha(140),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ArrowModelPainter extends CustomPainter {
  final Offset c0;
  final Offset c2;

  ArrowModelPainter(this.c0, this.c2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = Colors.black;
    final arrowPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.black;
    double angle = atan2(c2.dx - c0.dx, c2.dy - c0.dy);
    canvas.drawLine(c0, c2, paint);
    canvas.drawPath(
      getClip(Size(1000, 1000))
          .shift(Offset(-2, -2))
          .transform(Matrix4.rotationZ(pi * 3 / 2 - angle).storage)
          .shift(c2),
      arrowPaint,
    );
  }

  Path getClip(Size size) {
    Path path = Path();
    final double _xScaling = size.width / 413;
    final double _yScaling = size.height / 896;
    path.lineTo(0.75 * _xScaling, 8 * _yScaling);
    path.cubicTo(
      0.75 * _xScaling,
      8.3034 * _yScaling,
      0.5672999999999995 * _xScaling,
      8.576799999999999 * _yScaling,
      0.2870000000000008 * _xScaling,
      8.692900000000002 * _yScaling,
    );
    path.cubicTo(
      0.006800000000000139 * _xScaling,
      8.809000000000001 * _yScaling,
      -0.31583000000000006 * _xScaling,
      8.744900000000001 * _yScaling,
      -0.5303299999999993 * _xScaling,
      8.5304 * _yScaling,
    );
    path.cubicTo(
      -0.5303299999999993 * _xScaling,
      8.5304 * _yScaling,
      -6.53033 * _xScaling,
      2.5304 * _yScaling,
      -6.53033 * _xScaling,
      2.5304 * _yScaling,
    );
    path.cubicTo(
      -6.67098 * _xScaling,
      2.3896999999999995 * _yScaling,
      -6.75 * _xScaling,
      2.1989 * _yScaling,
      -6.75 * _xScaling,
      2 * _yScaling,
    );
    path.cubicTo(
      -6.75 * _xScaling,
      1.8011 * _yScaling,
      -6.67098 * _xScaling,
      1.6103000000000005 * _yScaling,
      -6.53033 * _xScaling,
      1.4696999999999996 * _yScaling,
    );
    path.cubicTo(
      -6.53033 * _xScaling,
      1.4696999999999996 * _yScaling,
      -0.5303299999999993 * _xScaling,
      -4.53031 * _yScaling,
      -0.5303299999999993 * _xScaling,
      -4.53031 * _yScaling,
    );
    path.cubicTo(
      -0.31583000000000006 * _xScaling,
      -4.74481 * _yScaling,
      0.006800000000000139 * _xScaling,
      -4.80897 * _yScaling,
      0.2870000000000008 * _xScaling,
      -4.69289 * _yScaling,
    );
    path.cubicTo(
      0.5672999999999995 * _xScaling,
      -4.5768 * _yScaling,
      0.75 * _xScaling,
      -4.30332 * _yScaling,
      0.75 * _xScaling,
      -3.99998 * _yScaling,
    );
    path.cubicTo(
      0.75 * _xScaling,
      -3.99998 * _yScaling,
      0.75 * _xScaling,
      8 * _yScaling,
      0.75 * _xScaling,
      8 * _yScaling,
    );
    path.cubicTo(
      0.75 * _xScaling,
      8 * _yScaling,
      0.75 * _xScaling,
      8 * _yScaling,
      0.75 * _xScaling,
      8 * _yScaling,
    );
    return path;
  }

  @override
  bool hitTest(Offset position) {
    final tolerance = 8.0;
    /*Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(x0, y0);
    
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 1) {
        final pos = metric.getTangentForOffset(d)!.position;
        if ((pos - position).distance <= tolerance) {
          return true;
        }
      }
    }
    return false;
    */
    if (quadraticBezierDistanceApprox(
          Point(position.dx, position.dy),
          Point(c0.dx, c0.dy),
          Point((c0.dx + c2.dx) / 2, (c0.dy + c2.dy) / 2),
          Point(c2.dx, c2.dy),
        ) <
        tolerance) {
      return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ViewScroller extends StatefulWidget {
  const ViewScroller(this.direction, {super.key});
  final Axis direction;

  @override
  State<ViewScroller> createState() => _ViewScrollerState();
}

class _ViewScrollerState extends State<ViewScroller> {
  double max = 10;
  double size = 2;
  double offset = 5;

  void setData({
    required double max,
    required double size,
    required double offset,
  }) {
    setState(() {
      this.max = max;
      this.size = size;
      this.offset = offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.direction == Axis.vertical) {
      return Positioned(
        top: 0,
        right: 0,
        bottom: 0,
        child: SizedBox(
          width: 10,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(height: constraints.maxHeight * (offset / max)),
                  Container(
                    height: constraints.maxHeight * (size / max),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } else {
      return Positioned(
        bottom: 0,
        right: 0,
        left: 0,
        child: SizedBox(
          height: 10,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(width: constraints.maxWidth * (offset / max)),
                  Container(
                    width: constraints.maxWidth * (size / max),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
  }
}

class Modular extends StatelessWidget {
  Modular(
    this.model,
    this.insideWidget,
    this.modelIds,
    this.refresh,
    this.controller,
    this.stackKey,
    this.coefficentOfResizing,
    this.models,
    this.node,
    this.modelKeys, {
    super.key,
  }) : width = ValueNotifier(model.width);
  final DropContentModel model;
  final bool insideWidget;
  final List<String> modelIds;
  final Function() refresh;
  final ValueNotifier<double> width;
  final TransformationController controller;
  final GlobalKey stackKey;
  final Offset coefficentOfResizing;
  final Map<String, DropModel> models;
  final FocusNode node;
  final Map<String, GlobalKey> modelKeys;

  @override
  Widget build(BuildContext context) {
    Widget? normalizedWidget;
    if (!insideWidget) {
      normalizedWidget = ValueListenableBuilder(
        valueListenable: width,
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.fromBorderSide(
                BorderSide(
                  color: Colors.black,
                  style: node.hasFocus ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            width: value,
            padding: EdgeInsets.all(16),
            child: (model is ColumnDropModel)
                ? ColumnWidget(
                    model as ColumnDropModel,
                    models,
                    modelIds,
                    refresh,
                    stackKey,
                    controller,
                    coefficentOfResizing,
                    modelKeys,
                  )
                : modulator(model, context),
          );
        },
      );
    } else {
      normalizedWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: (model is ColumnDropModel)
            ? ColumnWidget(
                model as ColumnDropModel,
                models,
                modelIds,
                refresh,
                stackKey,
                controller,
                coefficentOfResizing,
                modelKeys,
              )
            : modulator(model, context),
      );
    }

    Widget modelWidget = GestureDetector(
      onTap: () => node.requestFocus(),
      child: Focus(
        focusNode: node,
        descendantsAreFocusable: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.delete) {
              models.remove(model.id);
              modelIds.remove(model.id);
              refresh();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Draggable<String>(
              data: model.id,
              onDragUpdate: (details) {
                if (details.globalPosition.dx >
                    MediaQuery.of(context).size.width) {
                  final space =
                      details.globalPosition.dx -
                      MediaQuery.of(context).size.width;
                  Matrix4 tempMatrix = Matrix4.identity();
                  controller.value.copyInto(tempMatrix);
                  controller.value = tempMatrix..translate(-space, 0, 0);
                }
                if (details.globalPosition.dx < 0) {
                  Matrix4 tempMatrix = Matrix4.identity();
                  controller.value.copyInto(tempMatrix);
                  controller.value = tempMatrix
                    ..translate(-details.globalPosition.dx, 0, 0);
                }
                if (details.globalPosition.dy >
                    MediaQuery.of(context).size.height) {
                  final space =
                      details.globalPosition.dy -
                      MediaQuery.of(context).size.height;
                  Matrix4 tempMatrix = Matrix4.identity();
                  controller.value.copyInto(tempMatrix);
                  controller.value = tempMatrix..translate(0, -space, 0);
                }
                if (details.globalPosition.dy < 0) {
                  Matrix4 tempMatrix = Matrix4.identity();
                  controller.value.copyInto(tempMatrix);
                  controller.value = tempMatrix
                    ..translate(0, -details.globalPosition.dy, 0);
                }
              },
              onDragEnd: (details) {
                final renderBox =
                    stackKey.currentContext!.findRenderObject() as RenderBox;
                final vector =
                    renderBox.globalToLocal(details.offset) -
                    coefficentOfResizing;
                if (!details.wasAccepted) {
                  model.parentId = null;
                }
                model.x = vector.dx;
                model.y = vector.dy;
                if (!insideWidget) {
                  modelIds.remove(model.id);
                  modelIds.add(model.id);
                }
                //node.requestFocus();
                refresh();
              },
              childWhenDragging: SizedBox(),
              feedback: Transform.scale(
                scale: controller.value.row0[0],
                child: Material(
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(4, 4),
                          blurRadius: 4,
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withAlpha(120),
                        ),
                      ],
                    ),
                    child: insideWidget
                        ? SizedBox(width: model.width, child: normalizedWidget)
                        : normalizedWidget,
                  ),
                ),
              ),
              child: normalizedWidget,
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Sizer(model, width),
            ),
          ],
        ),
      ),
    );

    if (insideWidget) {
      return modelWidget;
    }
    return Positioned(
      left: model.x + coefficentOfResizing.dx,
      top: model.y + coefficentOfResizing.dy,
      child: modelWidget,
    );
  }
}

class Sizer extends StatefulWidget {
  const Sizer(this.model, this.width, {super.key});

  final DropContentModel model;
  final ValueNotifier<double> width;

  @override
  State<Sizer> createState() => _SizerState();
}

class _SizerState extends State<Sizer> {
  double x = 0;
  double originalWidth = 0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        x = details.localPosition.dx;
        originalWidth = widget.width.value;
      },
      onPanUpdate: (details) {
        final newWidth = originalWidth + details.localPosition.dx - x;
        if (newWidth > MINIMUN_WIDTH) {
          widget.width.value = newWidth;
          widget.model.width = newWidth;
        }
      },
      child: MouseRegion(cursor: SystemMouseCursors.resizeLeft),
    );
  }
}

Widget modulator(DropModel model, BuildContext context) {
  Widget? normalizedWidget;
  if (model is SimpleNoteDropModel) {
    normalizedWidget = SimpleNoteWidget(model);
  } else if (model is ImageDropModel) {
    normalizedWidget = ImageModelWidget(model);
  } else if (model is PageDropModel) {
    normalizedWidget = PageModelWidget(model);
  } else {
    normalizedWidget = Text("ModelIsUnknown");
  }
  return normalizedWidget;
}

class ColumnWidget extends StatelessWidget {
  ColumnWidget(
    this.model,
    this.models,
    this.modelIndicies,
    this.refresh,
    this.stackKey,
    this.controller,
    this.coefficentOfResizing,
    this.modelKeys, {
    super.key,
  }) : editingController = TextEditingController(text: model.title),
       selected = ValueNotifier(null);
  final ColumnDropModel model;
  final Map<String, DropModel> models;
  final List<String> modelIndicies;
  final Function() refresh;
  final TransformationController controller;
  final GlobalKey stackKey;
  final Offset coefficentOfResizing;
  final GlobalKey columnKey = GlobalKey();
  final TextEditingController editingController;
  final ValueNotifier<int?> selected;
  final Map<String, GlobalKey> modelKeys;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selected,
      builder: (context, value, child) => DragTarget<String>(
        onAcceptWithDetails: (details) {
          final modeler = models[details.data];
          if (modeler is DropContentModel) {
            value = null;
            modeler.parentId = model.id;
            refresh();
          }
        },
        onLeave: (data) {
          //models[data]?.parentId = null;
          value = null;
        },
        onMove: (details) {
          value = 0;
        },
        builder: (context, candidateData, rejectedData) {
          final modelIds = modelIndicies
              .where(
                (id) => models[id] is DropContentModel && models.containsKey(id)
                    ? (models[id] is DropContentModel
                          ? ((models[id] as DropContentModel).parentId ==
                                    model.id
                                ? true
                                : false)
                          : false)
                    : false,
              )
              .toList();
          return Column(
            key: columnKey,
            children: [
              FractionallySizedBox(
                widthFactor: 0.9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    maxLines: null,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    expands: false,
                    controller: editingController,
                    onChanged: (value) {
                      model.title = value;
                    },
                  ),
                ),
              ),
              /*SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    expands: false,
                    maxLength: null,
                    keyboardType: TextInputType.multiline,
                    controller: editingController,
                    onChanged: (value) {
                      widget.model.title = value;
                    },
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),*/
              Selector(0, value),
              for (int i = 0; i < modelIds.length; i++) ...[
                Modular(
                  models[modelIds[i]] as DropContentModel,
                  true,
                  modelIds,
                  refresh,
                  controller,
                  stackKey,
                  coefficentOfResizing,
                  models,
                  FocusNode(),
                  modelKeys,
                  key: getKey(modelIds[i]),
                ),
                Selector(i + 1, value),
              ],
            ],
          );
        },
      ),
    );
  }

  GlobalKey getKey(String id) {
    if (!modelKeys.containsKey(id)) {
      modelKeys[id] = GlobalKey();
    }
    return modelKeys[id]!;
  }
}

class Selector extends StatelessWidget {
  const Selector(this.index, this.selected, {super.key});
  final int index;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: index == selected ? Colors.black : Colors.transparent,
        ),
      ),
    );
  }
}

class SimpleNoteWidget extends StatelessWidget {
  SimpleNoteWidget(this.model, {super.key})
    : controller = TextEditingController(text: model.text);
  final SimpleNoteDropModel model;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
      expands: false,
      controller: controller,
      onChanged: (value) {
        model.text = value;
      },
    );
  }
}

class ImageModelWidget extends StatelessWidget {
  const ImageModelWidget(this.model, {super.key});
  final ImageDropModel model;

  @override
  Widget build(BuildContext context) {
    return Image.memory(model.image);
  }
}

class PageModelWidget extends StatelessWidget {
  PageModelWidget(this.model, {super.key})
    : controller = TextEditingController(text: model.title);
  final PageDropModel model;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onDoubleTap: () {
            try {
              final treeNames = Provider.of<InfoProvider>(
                context,
                listen: false,
              ).treeName;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FreePage([...treeNames, model.title], model.id),
                ),
              );
            } catch (e) {
              print("Error while trying going to another Page: $e");
            }
          },
          child: pageIcon(model.color, context, 1),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            expands: false,
            controller: controller,
            onChanged: (value) {
              model.title = value;
            },
          ),
        ),
      ],
    );
  }
}

Widget pageIcon(Color color, BuildContext context, double scaler) {
  return Container(
    padding: EdgeInsets.all(8 * scaler),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8 * scaler),
      color: Color.lerp(
        color,
        Theme.of(context).colorScheme.surfaceContainer,
        0.64,
      )!,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 12 * scaler,
              width: 12 * scaler,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2 * scaler),
                color: color,
              ),
            ),
            SizedBox(width: 8 * scaler),
            Container(
              height: 12 * scaler,
              width: 12 * scaler,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2 * scaler),
                color: Color.lerp(
                  color,
                  Theme.of(context).colorScheme.surfaceContainerLowest,
                  0.2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scaler),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 12 * scaler,
              width: 12 * scaler,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6 * scaler),
                color: Color.lerp(
                  color,
                  Theme.of(context).colorScheme.primary,
                  0.3,
                ),
              ),
            ),
            SizedBox(width: 8 * scaler),
            Container(
              height: 12 * scaler,
              width: 12 * scaler,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2 * scaler),
                color: color,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
