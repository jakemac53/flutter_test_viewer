import 'dart:async';

abstract class TestRunner {
  Future<TestResults> runAllTests();
}

abstract class TestResults {
  Stream<TestSuite> get testSuites;
}

abstract class TestSuite {
  Stream<TestGroup> get groups;
}

abstract class TestGroup {
  Stream<Test> get tests;
}

abstract class Test {
  String get name;
  Future<TestStatus> get status;
  Stream<void> get errors;
}

enum TestStatus {
  Succeess,
  Failure,
  Error,
}
