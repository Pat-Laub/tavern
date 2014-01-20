// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import '../entrypoint.dart';
import '../io.dart';
import '../log.dart' as log;
import '../source/hosted.dart';
import '../path_rep.dart';
import '../wrap/system_cache_wrap.dart';

typedef void LogFunction(String line, String level);

/// Gets the dependencies for the current project. The project is specified by
/// the working directory [entry], or if null then the previous project is
/// loaded from local storage.
Future getDependencies([html.DirectoryEntry entry, LogFunction extraLog]) {
  // Turn on the maximum level of logging, and hook up any extra log function.
  log.showAll();
  if (extraLog != null) log.addLoggerFunction(extraLog);

  return _loadWorkingDirectory(entry)
      .then((_) => SystemCache.withSources(FileSystem.workingDirPath()))
      ..catchError((e) => log.error("Could not create system cache", e))
      .then((cache) => Entrypoint.load(FileSystem.workingDirPath(), cache))
      .then((entrypoint) => entrypoint.acquireDependencies())
      .then((_) => log.fine("Got dependencies!"));
}

/// Load the working directory from either [entry] or from local storage.
/// Postcondition: FileSystem.workingDir will have a valid value.
Future<Directory> _loadWorkingDirectory(html.DirectoryEntry entry) {
  return new Future.sync(() {
    if (entry == null) {
      return FileSystem.restoreWorkingDirectory().then(
          (dir) => FileSystem.workingDir = dir);
    } else {
      var dir = new Directory(entry);
      FileSystem.persistWorkingDirectory(dir);
      return new Future.value(dir);
    }
  });
}

Future<List<String>> getAvailablePackageList() {
  return HostedSource.getHostedPackages();
}