// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartEvent _$StartEventFromJson(Map<String, dynamic> json) {
  return StartEvent(
    protocolVersion: json['protocolVersion'] as String,
    runnerVersion: json['runnerVersion'] as String,
    pid: json['pid'] as int,
  );
}

AllSuitesEvent _$AllSuitesEventFromJson(Map<String, dynamic> json) {
  return AllSuitesEvent(
    count: json['count'] as int,
  );
}

SuiteEvent _$SuiteEventFromJson(Map<String, dynamic> json) {
  return SuiteEvent(
    json['suite'] == null
        ? null
        : Suite.fromJson(json['suite'] as Map<String, dynamic>),
  );
}

DebugEvent _$DebugEventFromJson(Map<String, dynamic> json) {
  return DebugEvent(
    suiteID: json['suiteID'] as int,
    observatory: json['observatory'] as String,
    remoteDebugger: json['remoteDebugger'] as String,
  );
}

GroupEvent _$GroupEventFromJson(Map<String, dynamic> json) {
  return GroupEvent(
    group: json['group'] == null
        ? null
        : Group.fromJson(json['group'] as Map<String, dynamic>),
  );
}

TestStartEvent _$TestStartEventFromJson(Map<String, dynamic> json) {
  return TestStartEvent(
    test: json['test'] == null
        ? null
        : Test.fromJson(json['test'] as Map<String, dynamic>),
  );
}

MessageEvent _$MessageEventFromJson(Map<String, dynamic> json) {
  return MessageEvent(
    json['testID'] as int,
    json['messageType'] as String,
    json['message'] as String,
  );
}

ErrorEvent _$ErrorEventFromJson(Map<String, dynamic> json) {
  return ErrorEvent(
    testID: json['testID'] as int,
    error: json['error'] as String,
    stackTrace: json['stackTrace'] as String,
    isFailure: json['isFailure'] as bool,
  );
}

TestDoneEvent _$TestDoneEventFromJson(Map<String, dynamic> json) {
  return TestDoneEvent(
    testID: json['testID'] as int,
    result: json['result'] as String,
    hidden: json['hidden'] as bool,
    skipped: json['skipped'] as bool,
  );
}

DoneEvent _$DoneEventFromJson(Map<String, dynamic> json) {
  return DoneEvent(
    success: json['success'] as bool,
  );
}

Test _$TestFromJson(Map<String, dynamic> json) {
  return Test(
    id: json['id'] as int,
    name: json['name'] as String,
    suiteID: json['suiteID'] as int,
    groupIDs: (json['groupIDs'] as List)?.map((e) => e as int)?.toList(),
    line: json['line'] as int,
    column: json['column'] as int,
    url: json['url'] as String,
    rootLine: json['root_line'] as int,
    rootColumn: json['root_column'] as int,
    rootUrl: json['root_url'] as String,
  );
}

Suite _$SuiteFromJson(Map<String, dynamic> json) {
  return Suite(
    id: json['id'] as int,
    platform: json['platform'] as String,
    path: json['path'] as String,
  );
}

Group _$GroupFromJson(Map<String, dynamic> json) {
  return Group(
    id: json['id'] as int,
    name: json['name'] as String,
    suiteID: json['suiteID'] as int,
    parentID: json['parentID'] as int,
    testCount: json['testCount'] as int,
    line: json['line'] as int,
    column: json['column'] as int,
    url: json['url'] as String,
  );
}
