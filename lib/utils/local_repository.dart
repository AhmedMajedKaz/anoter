import 'dart:developer' as dev;

import 'package:anoter/models/drop_models.dart';
import 'package:idb_shim/idb_browser.dart';

class LocalRepository {
  static const String pageRecordName = 'pages';
  static const String modelRecordName = 'models';

  late Database db;

  Future<void> initialize() async {
    IdbFactory factory = idbFactoryBrowser;
    db = await factory.open(
      'drop_models.db',
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.database;
        if (!database.objectStoreNames.contains(pageRecordName)) {
          database.createObjectStore(pageRecordName);
        }
        if (!database.objectStoreNames.contains(modelRecordName)) {
          database.createObjectStore(modelRecordName);
        }
      },
    );
  }

  Future<DropPage> getDropPage(String id) async {
    try {
      var txn = db.transaction(pageRecordName, idbModeReadOnly);
      var data = List<String>.from(
        (await txn.objectStore(pageRecordName).getObject(id) ?? [])
            as List<dynamic>,
      );
      Map<String, DropModel> map = {};
      for (final modelId in data) {
        final model = await getDropModel(modelId);
        if (model != null) {
          map[modelId] = model;
        }
      }
      return DropPage(dropModels: map, dropOrder: List<String>.from(data));
    } catch (e) {
      dev.log("Error while Fetching local Data: $e");
      return DropPage(dropModels: {}, dropOrder: []);
    }
  }

  Future<void> saveDropPage(String id, DropPage page) async {
    try {
      var txn = db.transaction(pageRecordName, idbModeReadWrite);
      await txn.objectStore(pageRecordName).put(page.dropOrder, id);
      for (final entry in page.dropModels.entries) {
        await saveDropModel(entry.key, entry.value);
      }
    } catch (e) {
      dev.log("Error While Saving DropPage: $e");
    }
  }

  Future<DropModel?> getDropModel(String id) async {
    var txn = db.transaction(modelRecordName, idbModeReadOnly);
    var data = (await txn.objectStore(modelRecordName).getObject(id));
    if (data != null) {
      try {
        final map = data as Map<String, dynamic>;
        return DropModel.fromMap(map);
      } catch (e) {
        dev.log("Error while trying to convert to Map: $e");
      }
    }
    return null;
  }

  Future<void> saveDropModel(String id, DropModel model) async {
    var txn = db.transaction(modelRecordName, idbModeReadWrite);
    await txn.objectStore(modelRecordName).put(model.toMap, id);
  }
}
