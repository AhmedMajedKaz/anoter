import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

enum DropModelEnum {
  arrow('arrow'),
  note('note'),
  column('column'),
  image('image'),
  page('page');

  final String label;
  const DropModelEnum(this.label);

  @override
  String toString() => label;
}

class DropPage {
  Map<String, DropModel> dropModels;
  List<String> dropOrder;
  DropPage({required this.dropModels, required this.dropOrder});
}

class TextProperities {
  double size;
  TextProperities({required this.size});
}

abstract class DropModel {
  String id;
  double x;
  double y;
  DropModel({required this.id, required this.x, required this.y});
  Map<String, dynamic> get toMap;

  factory DropModel.fromMap(Map<String, dynamic> map) {
    switch (map['type']) {
      case 'arrow':
        return ArrowDropModel.fromMap(map);
      case 'column':
        return ColumnDropModel.fromMap(map);
      case 'image':
        return ImageDropModel.fromMap(map);
      case 'note':
        return SimpleNoteDropModel.fromMap(map);
      case 'page':
        return PageDropModel.fromMap(map);
      default:
        throw Exception("Unknown Drop Model: ${map['type']}");
    }
  }
}

abstract class DropContentModel extends DropModel {
  String? parentId;
  double width = 200;
  DropContentModel({
    required super.id,
    required this.parentId,
    required super.x,
    required super.y,
  });
}

class SimpleNoteDropModel extends DropContentModel {
  String text;
  SimpleNoteDropModel({required this.text})
    : super(x: 0, y: 0, id: Uuid().v4(), parentId: null);

  @override
  Map<String, dynamic> get toMap => {
    'type': DropModelEnum.note.label,
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'parent_id': parentId,
    'text': text,
  };

  factory SimpleNoteDropModel.fromMap(Map<String, dynamic> map) =>
      SimpleNoteDropModel(text: map['text'])
        ..parentId = map['parent_id']
        ..id = map['id']
        ..x = map['x']
        ..y = map['y']
        ..width = map['width'];
}

class ColumnDropModel extends DropContentModel {
  String title;
  ColumnDropModel({required this.title})
    : super(x: 0, y: 0, id: Uuid().v4(), parentId: null);

  @override
  Map<String, dynamic> get toMap => {
    'type': DropModelEnum.column.label,
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'parent_id': parentId,
    'title': title,
  };

  factory ColumnDropModel.fromMap(Map<String, dynamic> map) =>
      ColumnDropModel(title: map['title'])
        ..parentId = map['parent_id']
        ..id = map['id']
        ..x = map['x']
        ..y = map['y']
        ..width = map['width'];
}

class PageDropModel extends DropContentModel {
  String title;
  Color color;
  PageDropModel({required this.title, required this.color})
    : super(x: 0, y: 0, id: Uuid().v4(), parentId: null);
  @override
  Map<String, dynamic> get toMap => {
    'type': DropModelEnum.page.label,
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'parent_id': parentId,
    'title': title,
    'color': [color.a, color.r, color.b, color.g],
  };

  factory PageDropModel.fromMap(Map<String, dynamic> map) =>
      PageDropModel(
          title: map['title'],
          color: Color.fromARGB(
            (map['color'][0] * 255).floor(),
            (map['color'][1] * 255).floor(),
            (map['color'][2] * 255).floor(),
            (map['color'][3] * 255).floor(),
          ),
        )
        ..parentId = map['parent_id']
        ..id = map['id']
        ..x = map['x']
        ..y = map['y']
        ..width = map['width'];
}

class ImageDropModel extends DropContentModel {
  Uint8List image;
  String title;
  ImageDropModel({required this.title, required this.image})
    : super(x: 0, y: 0, id: Uuid().v4(), parentId: null);

  @override
  Map<String, dynamic> get toMap => {
    'type': DropModelEnum.image.label,
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'parent_id': parentId,
    'title': title,
    'image': image,
  };

  factory ImageDropModel.fromMap(Map<String, dynamic> map) =>
      ImageDropModel(title: map['title'], image: map['image'])
        ..parentId = map['parent_id']
        ..id = map['id']
        ..x = map['x']
        ..y = map['y']
        ..width = map['width'];
}

class ArrowDropModel extends DropModel {
  double x1;
  double? x2;
  double y1;
  double? y2;
  String? fromModelId;
  String? toModelId;
  ArrowDropModel({required this.x1, required this.y1})
    : super(id: Uuid().v4(), x: 0, y: 0);
  @override
  Map<String, dynamic> get toMap => {
    'type': DropModelEnum.arrow.label,
    'id': id,
    'x': x,
    'y': y,
    'x1': x1,
    if (x2 != null) 'x2': x2,
    'y1': y1,
    if (y2 != null) 'y2': y2,
    if (fromModelId != null) 'from': fromModelId,
    if (toModelId != null) 'to': toModelId,
  };

  factory ArrowDropModel.fromMap(Map<String, dynamic> map) =>
      ArrowDropModel(x1: map['x1'], y1: map['y1'])
        ..x2 = map['x2']
        ..y2 = map['y2']
        ..id = map['id']
        ..x = map['x']
        ..y = map['y']
        ..fromModelId = map['from']
        ..toModelId = map['to'];
}
