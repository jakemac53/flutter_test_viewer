import 'dart:async';

import 'models.dart';

abstract class TestRunner {
  TestResults runAllTests();

  TestResults runSuite(TestSuite suite);

  TestResults runTest(TestRun test);
}

abstract class TestResults {
  /// Returns a new stream each time which will emit all events.
  Stream<TestSuite> get testSuites;
}

abstract class TestSuite {
  Suite get suite;

  /// Return a new stream each time which will emit all events.
  Stream<TestGroup> get groups;
}

abstract class TestGroup {
  TestSuite get suite;

  Group get group;

  /// Return a new stream each time which will emit all events.
  Stream<TestRun> get tests;
}

abstract class TestRun {
  TestGroup get group;

  Test get test;

  Future<TestStatus> get status;

  /// Should be implemented as a broadcast stream.
  ///
  /// TODO: clean this up so you can get old errors and don't have to drop
  /// them on the floor.
  Stream<void> get errors;
}

enum TestStatus {
  Succeess,
  Failure,
  Error,
}
