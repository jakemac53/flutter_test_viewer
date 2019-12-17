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

Map<String, dynamic> _$StartEventToJson(StartEvent instance) =>
    <String, dynamic>{
      'protocolVersion': instance.protocolVersion,
      'runnerVersion': instance.runnerVersion,
      'pid': instance.pid,
    };

AllSuitesEvent _$AllSuitesEventFromJson(Map<String, dynamic> json) {
  return AllSuitesEvent(
    count: json['count'] as int,
  );
}

Map<String, dynamic> _$AllSuitesEventToJson(AllSuitesEvent instance) =>
    <String, dynamic>{
      'count': instance.count,
    };

SuiteEvent _$SuiteEventFromJson(Map<String, dynamic> json) {
  return SuiteEvent(
    json['suite'] == null
        ? null
        : Suite.fromJson(json['suite'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$SuiteEventToJson(SuiteEvent instance) =>
    <String, dynamic>{
      'suite': instance.suite,
    };

DebugEvent _$DebugEventFromJson(Map<String, dynamic> json) {
  return DebugEvent(
    suiteID: json['suiteID'] as int,
    observatory: json['observatory'] as String,
    remoteDebugger: json['remoteDebugger'] as String,
  );
}

Map<String, dynamic> _$DebugEventToJson(DebugEvent instance) =>
    <String, dynamic>{
      'suiteID': instance.suiteID,
      'observatory': instance.observatory,
      'remoteDebugger': instance.remoteDebugger,
    };

GroupEvent _$GroupEventFromJson(Map<String, dynamic> json) {
  return GroupEvent(
    group: json['group'] == null
        ? null
        : Group.fromJson(json['group'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$GroupEventToJson(GroupEvent instance) =>
    <String, dynamic>{
      'group': instance.group,
    };

TestStartEvent _$TestStartEventFromJson(Map<String, dynamic> json) {
  return TestStartEvent(
    test: json['test'] == null
        ? null
        : Test.fromJson(json['test'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TestStartEventToJson(TestStartEvent instance) =>
    <String, dynamic>{
      'test': instance.test,
    };

MessageEvent _$MessageEventFromJson(Map<String, dynamic> json) {
  return MessageEvent(
    json['testID'] as int,
    json['messageType'] as String,
    json['message'] as String,
  );
}

Map<String, dynamic> _$MessageEventToJson(MessageEvent instance) =>
    <String, dynamic>{
      'testID': instance.testID,
      'messageType': instance.messageType,
      'message': instance.message,
    };

ErrorEvent _$ErrorEventFromJson(Map<String, dynamic> json) {
  return ErrorEvent(
    testID: json['testID'] as int,
    error: json['error'] as String,
    stackTrace: json['stackTrace'] as String,
    isFailure: json['isFailure'] as bool,
  );
}

Map<String, dynamic> _$ErrorEventToJson(ErrorEvent instance) =>
    <String, dynamic>{
      'testID': instance.testID,
      'error': instance.error,
      'stackTrace': instance.stackTrace,
      'isFailure': instance.isFailure,
    };

TestDoneEvent _$TestDoneEventFromJson(Map<String, dynamic> json) {
  return TestDoneEvent(
    testID: json['testID'] as int,
    result: json['result'] as String,
    hidden: json['hidden'] as bool,
    skipped: json['skipped'] as bool,
  );
}

Map<String, dynamic> _$TestDoneEventToJson(TestDoneEvent instance) =>
    <String, dynamic>{
      'testID': instance.testID,
      'result': instance.result,
      'hidden': instance.hidden,
      'skipped': instance.skipped,
    };

DoneEvent _$DoneEventFromJson(Map<String, dynamic> json) {
  return DoneEvent(
    success: json['success'] as bool,
  );
}

Map<String, dynamic> _$DoneEventToJson(DoneEvent instance) => <String, dynamic>{
      'success': instance.success,
    };

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

Map<String, dynamic> _$TestToJson(Test instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'suiteID': instance.suiteID,
      'groupIDs': instance.groupIDs,
      'line': instance.line,
      'column': instance.column,
      'url': instance.url,
      'root_line': instance.rootLine,
      'root_column': instance.rootColumn,
      'root_url': instance.rootUrl,
    };

Suite _$SuiteFromJson(Map<String, dynamic> json) {
  return Suite(
    id: json['id'] as int,
    platform: json['platform'] as String,
    path: json['path'] as String,
  );
}

Map<String, dynamic> _$SuiteToJson(Suite instance) => <String, dynamic>{
      'id': instance.id,
      'platform': instance.platform,
      'path': instance.path,
    };

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

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'suiteID': instance.suiteID,
      'parentID': instance.parentID,
      'testCount': instance.testCount,
      'line': instance.line,
      'column': instance.column,
      'url': instance.url,
    };
