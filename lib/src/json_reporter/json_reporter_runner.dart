import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stream_transform/stream_transform.dart';

import '../models.dart';
import '../test_runner.dart';

class JsonReporterRunner implements TestRunner {
  @override
  TestResults runAllTests() {
    var testProcess = Process.start(
        'pub', ['run', 'test', '--reporter', 'json'],
        workingDirectory: '/usr/local/google/home/jakemac/build/build_modules');
    return _JsonReporterResults(testProcess);
  }

  @override
  TestResults runSuite(TestSuite suite) {
    var testProcess = Process.start(
        'pub',
        [
          'run',
          'test',
          '--reporter',
          'json',
          suite.suite.path,
          '-p',
          suite.suite.platform
        ],
        workingDirectory: '/usr/local/google/home/jakemac/build/build_modules');
    return _JsonReporterResults(testProcess);
  }

  @override
  TestResults runTest(TestRun test) {
    var suite = test.group.suite;
    var testProcess = Process.start(
        'pub',
        [
          'run',
          'test',
          '--reporter',
          'json',
          suite.suite.path,
          '-p',
          suite.suite.platform,
          '-n',
          test.test.name,
        ],
        workingDirectory: '/usr/local/google/home/jakemac/build/build_modules');
    return _JsonReporterResults(testProcess);
  }
}

class _JsonReporterResults implements TestResults {
  final _seenTestSuites = <TestSuite>[];

  @override
  Stream<TestSuite> get testSuites => Stream.fromIterable(_seenTestSuites)
      .followedBy(_testSuiteController.stream);
  final _testSuiteController = StreamController<TestSuite>.broadcast();

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
      process.stderr
          .map(utf8.decode)
          .transform(const LineSplitter())
          .listen(print);
    });
  }

  void _cleanUp() {
    _testSuiteController.close();
  }

  void _handleLine(String json) {
    print(json);
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
    _seenTestSuites.add(suite);
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
    if (event.test.groupIDs.isEmpty) return;
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
      if (!event.hidden) {
        throw StateError('No test with id `${event.testID}` found!');
      }
      return;
    }
    test.onDone(event);
  }

  void _handleDone(DoneEvent event) async {
    _suites.values.forEach((s) => s.close());
    for (var suite in _suites.values) {
      var status = await suite.status;
      if (status != TestStatus.Success) {
        _statusCompleter.complete(status);
        break;
      }
    }
    if (!_statusCompleter.isCompleted) {
      _statusCompleter.complete(TestStatus.Success);
    }
  }

  @override
  Future<TestStatus> get status => _statusCompleter.future;
  final _statusCompleter = Completer<TestStatus>();
}

class _JsonTestSuite implements TestSuite {
  final _seenGroups = <TestGroup>[];

  @override
  Stream<TestGroup> get groups =>
      Stream.fromIterable(_seenGroups).followedBy(_groupsController.stream);
  final _groupsController = StreamController<TestGroup>.broadcast();

  final Suite suite;

  final _activeTestGroups = <int, _JsonTestGroup>{};

  _JsonTestSuite(this.suite);

  void addGroup(_JsonTestGroup group) {
    _activeTestGroups[group.group.id] = group;
    _seenGroups.add(group);
    _groupsController.add(group);
  }

  void close() async {
    _groupsController.close();
    for (var group in _seenGroups) {
      var groupStatus = await group.status;
      if (groupStatus != TestStatus.Success) {
        _statusCompleter.complete(groupStatus);
        break;
      }
    }
    if (!_statusCompleter.isCompleted) {
      _statusCompleter.complete(TestStatus.Success);
    }
  }

  @override
  Future<TestStatus> get status => _statusCompleter.future;
  final _statusCompleter = Completer<TestStatus>();
}

class _JsonTestGroup implements TestGroup {
  final _seenTests = <TestRun>[];

  @override
  Stream<TestRun> get tests =>
      Stream.fromIterable(_seenTests).followedBy(_testController.stream);
  final _testController = StreamController<TestRun>.broadcast();

  final Group group;

  final _JsonTestSuite suite;

  // Includes number of tests from children.
  int _testsRan = 0;

  _JsonTestGroup(this.group, this.suite) {
    if (group.testCount == 0) close();
  }

  void addTest(_JsonTestTest test) {
    _seenTests.add(test);
    _testController.add(test);
    _testsRan++;
    if (_testsRan == group.testCount) close();

    _JsonTestGroup parent = this;

    _JsonTestGroup _nextParent() {
      if (parent.group.parentID != null) {
        parent = suite._activeTestGroups[parent.group.parentID];
        if (parent == null) {
          throw StateError('No group found with id ${group.parentID}!');
        }
      } else {
        parent = null;
      }
      return parent;
    }

    while (_nextParent() != null) {
      parent._testsRan++;
      if (parent._testsRan == parent.group.testCount) parent.close();
    }
  }

  void close() async {
    _testController.close();
    for (var test in _seenTests) {
      var testStatus = await test.status;
      if (testStatus != TestStatus.Success) {
        _statusCompleter.complete(testStatus);
        break;
      }
    }
    if (!_statusCompleter.isCompleted) {
      _statusCompleter.complete(TestStatus.Success);
    }
  }

  @override
  Future<TestStatus> get status => _statusCompleter.future;
  final _statusCompleter = Completer<TestStatus>();
}

class _JsonTestTest implements TestRun {
  @override
  Stream<void> get errors => _errorsController.stream;
  final _errorsController = StreamController<void>.broadcast();

  @override
  Future<TestStatus> get status => _statusCompleter.future;
  final _statusCompleter = Completer<TestStatus>();

  final Test test;

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
        status = TestStatus.Success;
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
