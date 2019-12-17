import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  }
}
