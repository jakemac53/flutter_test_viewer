import 'dart:async';

abstract class TestRunner {
  Future<TestResults> runAllTests();
}

abstract class TestResults {
  Stream<TestSuite> get testSuites;
}

class TestSuite {
  final Stream<TestGroup> groups;

  TestSuite(this.groups);
}

class TestGroup {
  final Stream<Test> tests;

  TestGroup(this.tests);
}

class Test {
  final String name;
  final Future<TestStatus> status;
  final Stream<void> errors;

  Test(this.name, this.status, this.errors);
}

enum TestStatus {
  Succeess,
  Failure,
  Timeout,
}
