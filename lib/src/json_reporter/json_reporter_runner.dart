import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models.dart' hide Test;
import '../models.dart' as models show Test;
import '../test_runner.dart';

class JsonReporterRunner implements TestRunner {
  @override
  TestResults runAllTests() {
    var testProcess =
        Process.start('pub', ['run', 'test', '--reporter', 'json']);
    return _JsonReporterResults(testProcess);
  }
}

class _JsonReporterResults implements TestResults {
  @override
  Stream<TestSuite> get testSuites => _testSuiteController.stream;
  final _testSuiteController = StreamController<TestSuite>();

  final _suites = <int, _JsonTestSuite>{};
  final _tests = <int, _JsonTestTest>{};

  _JsonReporterResults(Future<Process> testProcess) {
    testProcess.then((process) {
      process.exitCode.then((_) {
        _cleanUp();
      });

      process.stdout
          .map(utf8.decode)
          .transform(const LineSplitter())
          .listen(_handleLine);
    });
  }

  void _cleanUp() {
    _testSuiteController.close();
  }

  void _handleLine(String json) {
    var parsed = jsonDecode(json);
    var event = Event.parse(parsed);
    if (event is StartEvent || event is AllSuitesEvent || event is DebugEvent) {
      // ignore
    } else if (event is SuiteEvent) {
      _handleSuite(event);
    } else if (event is GroupEvent) {
      _handleGroup(event);
    } else if (event is TestStartEvent) {
      _handleTestStart(event);
    } else if (event is MessageEvent) {
      _handleMessage(event);
    } else if (event is ErrorEvent) {
      _handleError(event);
    } else if (event is TestDoneEvent) {
      _handleTestDone(event);
    } else if (event is DoneEvent) {
      _handleDone(event);
    } else {
      throw 'Unhandled event type ${event.runtimeType}';
    }
  }

  void _handleSuite(SuiteEvent event) {
    var suite = _JsonTestSuite(event.suite);
    _suites[suite.suite.id] = suite;
    _testSuiteController.add(suite);
  }

  void _handleGroup(GroupEvent event) {
    var suite = _suites[event.group.suiteID];
    if (suite == null) {
      throw StateError('No suite with id `${event.group.suiteID}` found!');
    }
    var group = _JsonTestGroup(event.group, suite);
    suite.addGroup(group);
  }

  void _handleTestStart(TestStartEvent event) {
    var suite = _suites[event.test.suiteID];
    var innerGroupId = event.test.groupIDs.last;
    var group = suite._activeTestGroups[innerGroupId];
    if (group == null) {
      throw StateError('No group with id `$innerGroupId` found!');
    }
    var test = _JsonTestTest(event.test, group);
    _tests[test.test.id] = test;
    group.addTest(test);
  }

  /// TODO: handle this better
  void _handleMessage(MessageEvent event) {
    print('${event.messageType}: ${event.message}');
  }

  void _handleError(ErrorEvent event) {
    var test = _tests[event.testID];
    if (test == null) {
      throw StateError('No test with id `${event.testID}` found!');
    }
    test.addError(event);
  }

  void _handleTestDone(TestDoneEvent event) {
    var test = _tests[event.testID];
    if (test == null) {
      throw StateError('No test with id `${event.testID}` found!');
    }
    test.onDone(event);
  }

  void _handleDone(DoneEvent event) {
    if (_tests.isNotEmpty) {
      throw StateError(
          'Got done event but ${_tests.length} tests are still running');
    }
  }
}

class _JsonTestSuite implements TestSuite {
  @override
  Stream<TestGroup> get groups => _groupsController.stream;
  final _groupsController = StreamController<TestGroup>();

  final Suite suite;

  final _activeTestGroups = <int, _JsonTestGroup>{};

  _JsonTestSuite(this.suite);

  void addGroup(_JsonTestGroup group) {
    _activeTestGroups[group.group.id] = group;
    _groupsController.add(group);
  }

  void close() => _groupsController.close();
}

class _JsonTestGroup implements TestGroup {
  @override
  Stream<TestRun> get tests => _testController.stream;
  final _testController = StreamController<TestRun>();

  final Group group;

  final _JsonTestSuite suite;

  _JsonTestGroup(this.group, this.suite);

  void addTest(_JsonTestTest test) {
    _testController.add(test);
  }

  void close() => _testController.close();
}

class _JsonTestTest implements TestRun {
  @override
  Stream<void> get errors => _errorsController.stream;
  final _errorsController = StreamController<void>();

  @override
  Future<TestStatus> get status => _statusCompleter.future;
  final _statusCompleter = Completer<TestStatus>();

  final models.Test test;

  final _JsonTestGroup group;

  _JsonTestTest(this.test, this.group) {
    _statusCompleter.future.then((_) => close());
  }

  void addError(ErrorEvent event) {
    _errorsController.addError(event);
  }

  void close() {
    _errorsController.close();
  }

  void onDone(TestDoneEvent event) {
    TestStatus status;
    switch (event.result) {
      case 'success':
        status = TestStatus.Succeess;
        break;
      case 'failure':
        status = TestStatus.Failure;
        break;
      case 'error':
        status = TestStatus.Error;
        break;
    }

    _statusCompleter.complete(status);
    close();
  }
}
