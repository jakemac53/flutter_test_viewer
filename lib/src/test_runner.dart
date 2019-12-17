import 'dart:async';

import 'models.dart';

abstract class TestRunner {
  TestResults runAllTests();
}

abstract class TestResults {
  Stream<TestSuite> get testSuites;
}

abstract class TestSuite {
  Suite get suite;

  Stream<TestGroup> get groups;
}

abstract class TestGroup {
  Group get group;

  Stream<TestRun> get tests;
}

abstract class TestRun {
  Test get test;

  Future<TestStatus> get status;
  Stream<void> get errors;
}

enum TestStatus {
  Succeess,
  Failure,
  Error,
}
