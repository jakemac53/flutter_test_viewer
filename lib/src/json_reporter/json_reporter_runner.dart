import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';
import '../test_runner.dart';

class JsonReporterRunner implements TestRunner {
  @override
  Future<TestResults> runAllTests() async {
    var testProcess =
        await Process.start('pub', ['run', 'test', '--reporter', 'json']);
    return _JsonReporterResults(testProcess);
  }
}

class _JsonReporterResults implements TestResults {
  final Process _testProcess;

  @override
  Stream<TestSuite> get testSuites => _testSuiteController.stream;
  final _testSuiteController = StreamController<TestSuite>();

  final _activeTestSuites = <int, _JsonTestSuite>{};

  _JsonReporterResults(this._testProcess) {
    _testProcess.exitCode.then((_) {
      _cleanUp();
    });

    _testProcess.stdout
        .map(utf8.decode)
        .transform(const LineSplitter())
        .listen(_handleLine);
  }

  void _cleanUp() {
    _testSuiteController.close();
  }

  void _handleLine(String json) {
    var parsed = jsonDecode(json);
    var event = Event.parse(parsed);
    if (event is SuiteEvent) {
      var suite = _JsonTestSuite(event.suite);
      _activeTestSuites[suite.suite.id] = suite;
      _testSuiteController.add(suite);
    }
  }
}

class _JsonTestSuite implements TestSuite {
  @override
  Stream<TestGroup> get groups => _groupsController.stream;
  final _groupsController = StreamController<TestGroup>();

  final Suite suite;

  _JsonTestSuite(this.suite);

  void close() => _groupsController.close();
}
