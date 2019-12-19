// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test_viewer/src/models.dart';
// import 'package:flutter/services.dart';

import 'package:flutter_test_viewer/src/test_runner.dart';
import 'package:flutter_test_viewer/src/json_reporter/json_reporter_runner.dart';

import 'package:provider/provider.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
        fontFamily: 'Roboto',
      ),
      home: HomePage(title: 'Dart Test Runner'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final suites = <TestSuite>[];
  StreamSubscription<TestSuite> _suiteListener;

  TestRunner _testRunner;

  @override
  void initState() {
    super.initState();

    _testRunner = JsonReporterRunner();
    _suiteListener = _testRunner.runAllTests().testSuites.listen((suite) {
      setState(() {
        suites.add(suite);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _suiteListener.cancel();
    _suiteListener = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: suites.length,
                itemBuilder: (context, index) {
                  var suite = suites[index];
                  return Provider<TestRunner>.value(
                    value: _testRunner,
                    child: TestSuiteListTile(
                        suite, () => _rerunSuite(context, index)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rerunSuite(BuildContext context, int index) async {
    var suite = suites[index];
    var results = _testRunner.runSuite(suite);
    var newSuite = await results.testSuites.single;
    setState(() {
      suites[index] = newSuite;
    });
  }
}

/// A list tile for a [TestSuite] which expands to show all the tests
/// and keeps itself alive when scrolled away so it can retain its state.
class TestSuiteListTile extends StatefulWidget {
  final TestSuite suite;

  final void Function() rerunSuite;

  TestSuiteListTile(this.suite, this.rerunSuite, {Key key}) : super(key: key);

  @override
  _TestSuiteListTileState createState() => _TestSuiteListTileState();
}

class _TestSuiteListTileState extends State<TestSuiteListTile> {
  TestSuite get suite => widget.suite;

  _TestSuiteListTileState();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        child: ExpansionTile(
          title: FutureBuilder(
              future: suite.status,
              builder: (_, snapshot) => Text(
                    '[${suite.suite.platform}] ${suite.suite.path}',
                    style: TextStyle(
                        color: _getColor(snapshot.data), fontSize: 20),
                  )),
          children: [TestSuiteWidget(suite)],
          trailing: FloatingActionButton(
            onPressed: widget.rerunSuite,
            tooltip: 'Re-run suite',
            child: new Icon(
              Icons.refresh,
            ),
            elevation: 4,
            mini: true,
          ),
        ),
      ),
    );
  }
}

class TestSuiteWidget extends StatefulWidget {
  TestSuiteWidget(this.suite, {Key key}) : super(key: key);

  final TestSuite suite;

  @override
  _TestSuiteState createState() => _TestSuiteState();
}

class _TestSuiteState extends State<TestSuiteWidget> {
  TestSuite get suite => widget.suite;
  final groups = <TestGroup>[];
  StreamSubscription<TestGroup> _groupListener;

  _TestSuiteState();

  @override
  void initState() {
    super.initState();
    _groupListener = suite.groups.listen((group) {
      setState(() {
        groups.add(group);
      });
    });
  }

  @override
  void didUpdateWidget(TestSuiteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _groupListener?.cancel();
    setState(() {
      groups.clear();
      _groupListener = suite.groups.listen((group) {
        setState(() {
          groups.add(group);
        });
      });
    });
    print('didUpdateWidget: TestSuiteWidget');
  }

  @override
  void dispose() {
    super.dispose();
    _groupListener.cancel();
    _groupListener = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var group in groups) TestGroupWidget(group),
      ],
    );
  }
}

class TestGroupWidget extends StatefulWidget {
  final TestGroup group;

  TestGroupWidget(this.group, {Key key}) : super(key: key);

  @override
  _TestGroupState createState() => _TestGroupState();
}

class _TestGroupState extends State<TestGroupWidget> {
  TestGroup get group => widget.group;
  final tests = <TestRun>[];

  StreamSubscription<TestRun> _testRunListener;

  _TestGroupState();

  @override
  void initState() {
    super.initState();
    _testRunListener = group.tests.listen((test) {
      setState(() {
        tests.add(test);
      });
    });
  }

  @override
  void didUpdateWidget(TestGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _testRunListener?.cancel();
    setState(() {
      tests.clear();
      _testRunListener = group.tests.listen((test) {
        setState(() {
          tests.add(test);
        });
      });
    });
    print('didUpdateWidget: TestGroupWidget');
  }

  @override
  void dispose() {
    super.dispose();
    _testRunListener.cancel();
    _testRunListener = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tests.length; i++)
          TestRunWidget(tests[i], () => _rerunTest(context, i)),
      ],
    );
  }

  void _rerunTest(BuildContext context, int index) async {
    var testRun = tests[index];
    var pending = PendingTestReRun(testRun);
    setState(() {
      tests[index] = pending;
    });
    var testRunner = Provider.of<TestRunner>(context);
    var results = testRunner.runTest(testRun);
    var suite = await results.testSuites.single;
    TestRun newTestRun;
    await for (var group in suite.groups) {
      if (newTestRun != null) break;
      await for (var test in group.tests) {
        if (test.test.name == testRun.test.name) {
          newTestRun = test;
          break;
        }
      }
    }
    setState(() {
      pending._statusCompleter.complete(newTestRun.status);
    });
  }
}

class TestRunWidget extends StatefulWidget {
  final TestRun testRun;
  final void Function() rerunTest;

  TestRunWidget(this.testRun, this.rerunTest, {Key key}) : super(key: key);

  @override
  _TestRunState createState() => _TestRunState();
}

class _TestRunState extends State<TestRunWidget> {
  TestRun get testRun => widget.testRun;

  @override
  void didUpdateWidget(TestRunWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget: TestRunWidget');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: FutureBuilder(
            future: testRun.status,
            builder: (_, snapshot) => Text(
                  testRun.test.name,
                  style: TextStyle(color: _getColor(snapshot.data)),
                )),
        trailing: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: FloatingActionButton(
            onPressed: widget.rerunTest,
            tooltip: 'Re-run test',
            child: new Icon(
              Icons.refresh,
            ),
            elevation: 4,
            mini: true,
          ),
        ),
        dense: true,
      ),
    );
  }
}

class PendingTestReRun implements TestRun {
  @override
  Stream<void> get errors => _errorsController.stream;
  final _errorsController = StreamController<void>.broadcast();

  @override
  TestGroup get group => _original.group;

  @override
  Future<TestStatus> status = Future.value(null);
  final _statusCompleter = Completer<TestStatus>();

  @override
  // TODO: Update other fields from the test (line # etc?)
  Test get test => _original.test;

  final TestRun _original;

  PendingTestReRun(this._original) {
    _statusCompleter.future.whenComplete(() {
      _errorsController.close();
      status = _statusCompleter.future;
    });
  }
}

Color _getColor(TestStatus status) {
  if (status == null) return Colors.grey;
  switch (status) {
    case TestStatus.Success:
      return Colors.green;
      break;
    case TestStatus.Error:
    case TestStatus.Failure:
      return Colors.red;
      break;
  }
  throw StateError('Unreachable code');
}
