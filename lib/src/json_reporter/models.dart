import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

abstract class Event {
  // The type of the event.
  //
  // This is always one of the subclass types listed below.
  String get type;

  static Event parse(Map<String, dynamic> json) {
    var eventType = json['type'];
    switch (eventType) {
      case 'start':
        return StartEvent.fromJson(json);
      case 'allSuites':
        return AllSuitesEvent.fromJson(json);
      case 'suite':
        return SuiteEvent.fromJson(json);
      case 'debug':
        return DebugEvent.fromJson(json);
      case 'group':
        return GroupEvent.fromJson(json);
      case 'testStart':
        return TestStartEvent.fromJson(json);
      case 'print':
        return MessageEvent.fromJson(json);
      case 'error':
        return ErrorEvent.fromJson(json);
      case 'testDone':
        return TestDoneEvent.fromJson(json);
      case 'done':
        return DoneEvent.fromJson(json);
      default:
        throw UnsupportedError(
            'Unsupporte event type `$eventType`, full JSON object was:\n'
            '${JsonEncoder.withIndent('  ').convert(json)}');
    }
  }
}

@JsonSerializable(createToJson: false)
class StartEvent implements Event {
  String get type => 'start';

  // The version of the JSON reporter protocol being used.
  //
  // This is a semantic version, but it reflects only the version of the
  // protocol—it's not identical to the version of the test runner itself.
  final String protocolVersion;

  // The version of the test runner being used.
  final String runnerVersion;

  // The pid of the VM process running the tests.
  final int pid;

  StartEvent({this.protocolVersion, this.runnerVersion, this.pid});

  factory StartEvent.fromJson(Map<String, dynamic> json) =>
      _$StartEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class AllSuitesEvent implements Event {
  String get type => 'allSuites';

  /// The total number of suites that will be loaded.
  final int count;

  AllSuitesEvent({this.count});

  factory AllSuitesEvent.fromJson(Map<String, dynamic> json) =>
      _$AllSuitesEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class SuiteEvent implements Event {
  String get type => 'suite';

  /// Metadata about the suite.
  final Suite suite;

  SuiteEvent(this.suite);

  factory SuiteEvent.fromJson(Map<String, dynamic> json) =>
      _$SuiteEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DebugEvent implements Event {
  String get type => 'debug';

  /// The suite for which debug information is reported.
  final int suiteID;

  /// The HTTP URL for the Dart Observatory, or `null` if the Observatory isn't
  /// available for this suite.
  final String observatory;

  /// The HTTP URL for the remote debugger for this suite's host page, or `null`
  /// if no remote debugger is available for this suite.
  final String remoteDebugger;

  DebugEvent({this.suiteID, this.observatory, this.remoteDebugger});

  factory DebugEvent.fromJson(Map<String, dynamic> json) =>
      _$DebugEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class GroupEvent implements Event {
  String get type => 'group';

  /// Metadata about the group.
  final Group group;

  GroupEvent({this.group});

  factory GroupEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class TestStartEvent implements Event {
  String get type => 'testStart';

  // Metadata about the test that started.
  final Test test;

  TestStartEvent({this.test});

  factory TestStartEvent.fromJson(Map<String, dynamic> json) =>
      _$TestStartEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class MessageEvent implements Event {
  String get type => 'print';

  // The ID of the test that printed a message.
  final int testID;

  // The type of message being printed.
  final String messageType;

  // The message that was printed.
  final String message;

  MessageEvent(this.testID, this.messageType, this.message);

  factory MessageEvent.fromJson(Map<String, dynamic> json) =>
      _$MessageEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class ErrorEvent implements Event {
  String get type => 'error';

  // The ID of the test that experienced the error.
  final int testID;

  // The result of calling toString() on the error object.
  final String error;

  // The error's stack trace, in the stack_trace package format.
  final String stackTrace;

  // Whether the error was a TestFailure.
  final bool isFailure;

  ErrorEvent({this.testID, this.error, this.stackTrace, this.isFailure});

  factory ErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$ErrorEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class TestDoneEvent implements Event {
  String get type => 'testDone';

  // The ID of the test that completed.
  final int testID;

  // The result of the test.
  final String result;

  // Whether the test's result should be hidden.
  final bool hidden;

  // Whether the test (or some part of it) was skipped.
  final bool skipped;

  TestDoneEvent({this.testID, this.result, this.hidden, this.skipped});

  factory TestDoneEvent.fromJson(Map<String, dynamic> json) =>
      _$TestDoneEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DoneEvent implements Event {
  String get type => 'done';

  // Whether all tests succeeded (or were skipped).
  final bool success;

  DoneEvent({this.success});

  factory DoneEvent.fromJson(Map<String, dynamic> json) =>
      _$DoneEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class Test {
  // An opaque ID for the test.
  final int id;

  // The name of the test, including prefixes from any containing groups.
  final String name;

  // The ID of the suite containing this test.
  final int suiteID;

  // The IDs of groups containing this test, in order from outermost to
  // innermost.
  final List<int> groupIDs;

  // The (1-based) line on which the test was defined, or `null`.
  final int line;

  // The (1-based) column on which the test was defined, or `null`.
  final int column;

  // The URL for the file in which the test was defined, or `null`.
  final String url;

  // The (1-based) line in the original test suite from which the test
  // originated.
  //
  // Will only be present if `root_url` is different from `url`.
  @JsonKey(name: 'root_line')
  final int rootLine;

  // The (1-based) line on in the original test suite from which the test
  // originated.
  //
  // Will only be present if `root_url` is different from `url`.
  @JsonKey(name: 'root_column')
  final int rootColumn;

  // The URL for the original test suite in which the test was defined.
  //
  // Will only be present if different from `url`.
  @JsonKey(name: 'root_url')
  final String rootUrl;

  Test(
      {this.id,
      this.name,
      this.suiteID,
      this.groupIDs,
      this.line,
      this.column,
      this.url,
      this.rootLine,
      this.rootColumn,
      this.rootUrl});

  factory Test.fromJson(Map<String, dynamic> json) => _$TestFromJson(json);
}

@JsonSerializable(createToJson: false)
class Suite {
  // An opaque ID for the group.
  final int id;

  // The platform on which the suite is running.
  final String /* ? */ platform;

  // The path to the suite's file.
  final String path;

  Suite({this.id, this.platform, this.path});

  factory Suite.fromJson(Map<String, dynamic> json) => _$SuiteFromJson(json);
}

@JsonSerializable(createToJson: false)
class Group {
  // An opaque ID for the group.
  final int id;

  // The name of the group, including prefixes from any containing groups.
  final String /* ? */ name;

  // The ID of the suite containing this group.
  final int suiteID;

  // The ID of the group's parent group, unless it's the root group.
  final int /* ? */ parentID;

  // The number of tests (recursively) within this group.
  final int testCount;

  // The (1-based) line on which the group was defined, or `null`.
  final int line;

  // The (1-based) column on which the group was defined, or `null`.
  final int column;

  // The URL for the file in which the group was defined, or `null`.
  final String url;

  Group(
      {this.id,
      this.name,
      this.suiteID,
      this.parentID,
      this.testCount,
      this.line,
      this.column,
      this.url});

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
