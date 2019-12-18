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
  final suites = <int, TestSuite>{};
  StreamSubscription<TestSuite> _suiteListener;

  TestRunner _testRunner;

  @override
  void initState() {
    super.initState();

    _testRunner = JsonReporterRunner();
    _suiteListener = _testRunner.runAllTests().testSuites.listen((suite) {
      setState(() {
        suites[suite.suite.id] = suite;
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
                itemCount: suites.values.length,
                itemBuilder: (context, index) {
                  var suite = suites.values.elementAt(index);
                  return Provider<TestRunner>.value(
                    value: _testRunner,
                    child: TestSuiteListTile(suite),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list tile for a [TestSuite] which expands to show all the tests
/// and keeps itself alive when scrolled away so it can retain its state.
class TestSuiteListTile extends StatefulWidget {
  final TestSuite suite;

  TestSuiteListTile(this.suite, {Key key}) : super(key: key);

  @override
  _TestSuiteListTileState createState() => _TestSuiteListTileState(suite);
}

class _TestSuiteListTileState extends State<TestSuiteListTile>
    with AutomaticKeepAliveClientMixin {
  final TestSuite suite;

  _TestSuiteListTileState(this.suite);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      child: Card(
        child: ExpansionTile(
          title: Text(
            '[${suite.suite.platform}] ${suite.suite.path}',
            style: TextStyle(fontSize: 20),
          ),
          children: [TestSuiteWidget(suite)],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TestSuiteWidget extends StatefulWidget {
  TestSuiteWidget(this.suite, {Key key}) : super(key: key);

  final TestSuite suite;

  @override
  _TestSuiteState createState() => _TestSuiteState(suite);
}

class _TestSuiteState extends State<TestSuiteWidget> {
  final TestSuite suite;
  final groups = <int, TestGroup>{};
  StreamSubscription<TestGroup> _groupListener;

  _TestSuiteState(this.suite);

  @override
  void didUpdateWidget(TestSuiteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _groupListener = suite.groups.listen((group) {
      setState(() {
        groups[group.group.id] = group;
      });
    });
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
        for (var group in groups.values) TestGroupWidget(group),
      ],
    );
  }
}

class TestGroupWidget extends StatefulWidget {
  TestGroupWidget(this.group, {Key key}) : super(key: key);

  final TestGroup group;

  @override
  _TestGroupState createState() => _TestGroupState(group);
}

class _TestGroupState extends State<TestGroupWidget> {
  final TestGroup group;
  final tests = <int, TestRun>{};

  StreamSubscription<TestRun> _testRunListener;

  _TestGroupState(this.group);

  @override
  void initState() {
    super.initState();
    _testRunListener = group.tests.listen((test) {
      setState(() {
        tests[test.test.id] = test;
      });
    });
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
        for (var test in tests.values) TestRunWidget(test),
      ],
    );
  }
}

class TestRunWidget extends StatefulWidget {
  TestRunWidget(this.testRun, {Key key}) : super(key: key);

  final TestRun testRun;

  @override
  _TestRunState createState() => _TestRunState(testRun);
}

class _TestRunState extends State<TestRunWidget> {
  TestRun testRun;

  _TestRunState(this.testRun);

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
            onPressed: () => _rerunTest(context),
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

  Color _getColor(TestStatus status) {
    print(
        'Getting color for test ${testRun.test.name} with status $status - ${testRun.runtimeType}');
    if (status == null) return Colors.grey;
    switch (status) {
      case TestStatus.Succeess:
        return Colors.green;
        break;
      case TestStatus.Error:
      case TestStatus.Failure:
        return Colors.red;
        break;
    }
    throw StateError('Unreachable code');
  }

  void _rerunTest(context) async {
    var pending = PendingTestReRun(testRun);
    setState(() {
      testRun = pending;
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
