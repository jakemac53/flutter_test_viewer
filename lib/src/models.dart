import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// This is the root class of the protocol. All root-level objects emitted by
/// the JSON reporter will be subclasses of `Event`.
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

/// A single start event is emitted before any other events. It indicates that
/// the test runner has started running.
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

/// A single suite count event is emitted once the test runner knows the total
/// number of suites that will be loaded over the course of the test run.
/// Because this is determined asynchronously, its position relative to other
/// events (except `StartEvent`) is not guaranteed.
@JsonSerializable(createToJson: false)
class AllSuitesEvent implements Event {
  String get type => 'allSuites';

  /// The total number of suites that will be loaded.
  final int count;

  AllSuitesEvent({this.count});

  factory AllSuitesEvent.fromJson(Map<String, dynamic> json) =>
      _$AllSuitesEventFromJson(json);
}

/// A suite event is emitted before any `GroupEvent`s for groups in a given
/// test suite. This is the only event that contains the full metadata about a
/// suite; future events will refer to the suite by its opaque ID.
@JsonSerializable(createToJson: false)
class SuiteEvent implements Event {
  String get type => 'suite';

  /// Metadata about the suite.
  final Suite suite;

  SuiteEvent(this.suite);

  factory SuiteEvent.fromJson(Map<String, dynamic> json) =>
      _$SuiteEventFromJson(json);
}

///  A debug event is emitted after (although not necessarily directly after) a
/// `SuiteEvent`, and includes information about how to debug that suite. It's
/// only emitted if the `--debug` flag is passed to the test runner.

/// Note that the `remoteDebugger` URL refers to a remote debugger whose
/// protocol may differ based on the browser the suite is running on. You can
/// tell which protocol is in use by the `Suite.platform` field for the suite
/// with the given ID. Since the same browser instance is used for multiple
/// suites, different suites may have the same `host` URL, although only one
/// suite at a time will be active when `--pause-after-load` is passed.
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

/// A group event is emitted before any `TestStartEvent`s for tests in a given
/// group. This is the only event that contains the full metadata about a
/// group; future events will refer to the group by its opaque ID.
///
/// This includes the implicit group at the root of each suite, which has a
/// `null` name. However, it does *not* include implicit groups for the virtual
/// suites generated to represent loading test files.
///
/// If the group is skipped, a single `TestStartEvent` will be emitted for a
/// test within the group, followed by a `TestDoneEvent` marked as skipped. The
/// `group.metadata` field should *not* be used for determining whether a group
/// is skipped.
@JsonSerializable(createToJson: false)
class GroupEvent implements Event {
  String get type => 'group';

  /// Metadata about the group.
  final Group group;

  GroupEvent({this.group});

  factory GroupEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupEventFromJson(json);
}

/// An event emitted when a test begins running. This is the only event that
/// contains the full metadata about a test; future events will refer to the
/// test by its opaque ID.
///
/// If the test is skipped, its `TestDoneEvent` will have `skipped` set to
/// `true`. The `test.metadata` should *not* be used for determining whether a
/// test is skipped.
@JsonSerializable(createToJson: false)
class TestStartEvent implements Event {
  String get type => 'testStart';

  // Metadata about the test that started.
  final Test test;

  TestStartEvent({this.test});

  factory TestStartEvent.fromJson(Map<String, dynamic> json) =>
      _$TestStartEventFromJson(json);
}

/// A `MessageEvent` indicates that a test emitted a message that should be
/// displayed to the user. The `messageType` field indicates the precise type
/// of this message. Different message types should be visually
/// distinguishable.
///
/// A message of type "print" comes from a user explicitly calling `print()`.
///
/// A message of type "skip" comes from a test, or a section of a test, being
/// skipped. A skip message shouldn't be considered the authoritative source
/// that a test was skipped; the `TestDoneEvent.skipped` field should be used
/// instead.
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

/// A `ErrorEvent` indicates that a test encountered an uncaught error. Note
/// that this may happen even after the test has completed, in which case it
/// should be considered to have failed.
///
/// If a test is asynchronous, it may encounter multiple errors, which will
/// result in multiple `ErrorEvent`s.
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

/// An event emitted when a test completes. The `result` attribute indicates
/// the result of the test:
///
/// * `"success"` if the test had no errors.
/// * `"failure"` if the test had a `TestFailure` but no other errors.
/// * `"error"` if the test had an error other than a `TestFailure`.
///
/// If the test encountered an error, the `TestDoneEvent` will be emitted after
/// the corresponding `ErrorEvent`.
///
/// The `hidden` attribute indicates that the test's result should be hidden
/// and not counted towards the total number of tests run for the suite. This
/// is true for virtual tests created for loading test suites, `setUpAll()`,
/// and `tearDownAll()`. Only successful tests will be hidden.
///
/// Note that it's possible for a test to encounter an error after completing.
/// In that case, it should be considered to have failed, but no additional
/// `TestDoneEvent` will be emitted. If a previously-hidden test encounters an
/// error after completing, it should be made visible.
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

/// An event indicating the result of the entire test run. This will be the
/// final event emitted by the reporter.
@JsonSerializable(createToJson: false)
class DoneEvent implements Event {
  String get type => 'done';

  // Whether all tests succeeded (or were skipped).
  final bool success;

  DoneEvent({this.success});

  factory DoneEvent.fromJson(Map<String, dynamic> json) =>
      _$DoneEventFromJson(json);
}

/// A single test case. The test's ID is unique in the context of this test
/// run. It's used elsewhere in the protocol to refer to this test without
/// including its full representation.
///
/// Most tests will have at least one group ID, representing the implicit root
/// group. However, some may not; these should be treated as having no group
/// metadata.
///
/// The `line`, `column`, and `url` fields indicate the location the `test()`
/// function was called to create this test. They're treated as a unit: they'll
/// either all be `null` or they'll all be non-`null`. The URL is always
/// absolute, and may be a `package:` URL.
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

/// A test suite corresponding to a loaded test file. The suite's ID is unique
/// in the context of this test run. It's used elsewhere in the protocol to
/// refer to this suite without including its full representation.
///
/// A suite's platform is one of the platforms that can be passed to the
/// `--platform` option, or `null` if there is no platform (for example if the
/// file doesn't exist at all). Its path is either absolute or relative to the
/// root of the current package.
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
