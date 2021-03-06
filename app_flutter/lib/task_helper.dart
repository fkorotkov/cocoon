// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show Commit, Task;

/// A collection of common utilities done with a [Task].

/// Base URLs for various endpoints that can relate to a [Task].
const String flutterGithubSourceUrl =
    'https://github.com/flutter/flutter/blob/master';
const String flutterDashboardUrl = 'https://flutter-dashboard.appspot.com';
const String cirrusUrl = 'https://cirrus-ci.com/github/flutter/flutter';
const String cirrusLogUrl = 'https://cirrus-ci.com/build/flutter/flutter';
const String luciUrl = 'https://ci.chromium.org/p/flutter';

/// [Task.stageName] that maps to StageName enums.
// TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
class StageName {
  static const String cirrus = 'cirrus';
  static const String luci = 'chromebot';
  static const String devicelab = 'devicelab';
  static const String devicelabWin = 'devicelab_win';
  static const String devicelabIOs = 'devicelab_ios';
}

/// Get the URL for [Task] to view its log.
///
/// Devicelab tasks can be retrieved via an authenticated API endpoint.
/// Cirrus logs are located via their [Commit.sha].
/// Otherwise, we can redirect to the page that is closest to the logs for [Task].
String logUrl(Task task, {Commit commit}) {
  if (task.stageName == StageName.cirrus && commit != null) {
    return '$cirrusLogUrl/${commit.sha}';
  } else if (_isExternal(task)) {
    // Currently this is just LUCI, but is a catch all if new stages are added.
    return sourceConfigurationUrl(task);
  }

  return '$flutterDashboardUrl/api/get-log?ownerKey=${task.key.child.name}';
}

/// Get the URL for [Task] that shows its configuration.
///
/// Devicelab tasks are stored in the flutter/flutter Github repository.
/// Luci tasks are stored on Luci.
/// Cirrus tasks are stored on Cirrus.
///
/// Throws [Exception] if [Task] does not match any of the above sources.
String sourceConfigurationUrl(Task task) {
  if (_isExternal(task)) {
    return _externalSourceConfigurationUrl(task);
  }

  return '$flutterGithubSourceUrl/dev/devicelab/bin/tasks/${task.name}.dart';
}

String _externalSourceConfigurationUrl(Task task) {
  if (task.stageName == StageName.luci) {
    return _luciSourceConfigurationUrl(task);
  } else if (task.stageName == StageName.cirrus) {
    return '$cirrusUrl/master';
  }

  throw Exception(
      'Failed to get source configuration url for ${task.stageName}');
}

String _luciSourceConfigurationUrl(Task task) {
  switch (task.name) {
    case 'mac_bot':
      return '$luciUrl/builders/luci.flutter.prod/Mac';
    case 'linux_bot':
      return '$luciUrl/builders/luci.flutter.prod/Linux';
    case 'windows_bot':
      return '$luciUrl/builders/luci.flutter.prod/Windows';
  }

  return luciUrl;
}

/// Whether [Task] is run in the devicelab or not.
bool isDevicelab(Task task) => task.stageName.contains(StageName.devicelab);

/// Whether the information from [Task] is available publically.
///
/// Only devicelab tasks are not available publically.
bool _isExternal(Task task) =>
    task.stageName == StageName.luci || task.stageName == StageName.cirrus;

class TaskHelper {}
