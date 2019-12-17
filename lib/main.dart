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
// import 'package:flutter/services.dart';

import 'package:flutter_test_viewer/src/test_runner.dart';
import 'package:flutter_test_viewer/src/json_reporter/json_reporter_runner.dart';

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

  @override
  void initState() {
    super.initState();

    var runner = JsonReporterRunner();
    _suiteListener = runner.runAllTests().testSuites.listen((suite) {
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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200.0),
                child: ListView.builder(
                  itemCount: suites.values.length,
                  itemBuilder: (context, index) {
                    var suite = suites.values.elementAt(index);
                    return ExpansionTile(
                        title: Text(
                          '[${suite.suite.platform}] ${suite.suite.path}',
                          style: TextStyle(fontSize: 20),
                        ),
                        children: [
                          Padding(
                              padding: EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: TestSuiteWidget(suite)),
                        ]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        for (var group in groups.values)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: TestGroupWidget(group),
          ),
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
        if (group.group.name != null)
          Row(children: [
            Text('Group: ${group.group.name}'),
          ]),
        for (var test in tests.values)
          Row(children: [
            Padding(
              child: TestRunWidget(test),
              padding: EdgeInsets.only(left: 8, top: 4),
            ),
          ]),
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
  final TestRun testRun;
  TestStatus status;

  _TestRunState(this.testRun);

  @override
  void initState() {
    super.initState();
    testRun.status.then((status) {
      setState(() {
        this.status = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'Test: ${testRun.test.name}',
          style: TextStyle(color: _getColor()),
        ),
      ],
    );
  }

  Color _getColor() {
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
}
