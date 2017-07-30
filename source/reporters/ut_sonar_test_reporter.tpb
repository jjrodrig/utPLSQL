create or replace type body ut_sonar_test_reporter is
  /*
  utPLSQL - Version X.X.X.X
  Copyright 2016 - 2017 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  constructor function ut_sonar_test_reporter(
    self in out nocopy ut_sonar_test_reporter
  ) return self as result is
  begin
    self.init($$plsql_unit);
    return;
  end;

  overriding member procedure before_calling_run(self in out nocopy ut_sonar_test_reporter, a_run in ut_run) is
  begin
    self.file_mappings := coalesce(a_run.test_file_mappings,ut_file_mappings());
    self.print_text('<testExecutions version="1">');
  end;

  overriding member procedure before_calling_suite(self in out nocopy ut_sonar_test_reporter, a_suite ut_logical_suite) is
    l_file_name varchar2(4000);
  begin
    for i in 1 .. self.file_mappings.count loop
      if upper(self.file_mappings(i).object_name) = upper(a_suite.object_name)
        and upper(self.file_mappings(i).object_owner) = upper(a_suite.object_owner) then
        l_file_name := self.file_mappings(i).file_name;
        exit;
      end if;
    end loop;
    l_file_name := coalesce(l_file_name, a_suite.path);
    self.print_text('<file path="'||l_file_name||'">');
  end;

  overriding member procedure after_calling_test(self in out nocopy ut_sonar_test_reporter, a_test ut_test) is
    l_message varchar2(32757);
    l_lines ut_varchar2_list;
  begin
    ut_utils.append(l_lines, '<testCase name="'||a_test.name||'" duration="'||round(a_test.execution_time()*1000,0)||'" >');
    if a_test.result = ut_utils.tr_disabled then
      ut_utils.append(l_lines, '<skipped message="skipped"/>');
    elsif a_test.result = ut_utils.tr_error then
      ut_utils.append(l_lines, '<error message="encountered errors">');
      ut_utils.append(l_lines, '<![CDATA[');
      ut_utils.append(l_lines, a_test.get_error_stack_traces());
      ut_utils.append(l_lines, ']]>');
      ut_utils.append(l_lines, '</error>');
    elsif a_test.result > ut_utils.tr_success then
      ut_utils.append(l_lines, '<failure message="some expectations have failed">');
      ut_utils.append(l_lines, '<![CDATA[');
      for i in 1 .. a_test.results.count loop
        ut_utils.append(l_lines, a_test.results(i).get_result_lines());
      end loop;
      ut_utils.append(l_lines, ']]>');
      ut_utils.append(l_lines, '</failure>');
    end if;
    ut_utils.append(l_lines, '</testCase>');
    self.print_lines(l_lines);
  end;

  overriding member procedure after_calling_suite(self in out nocopy ut_sonar_test_reporter, a_suite ut_logical_suite) is
  begin
    self.print_text('</file>');
  end;

  overriding member procedure after_calling_run(self in out nocopy ut_sonar_test_reporter, a_run in ut_run) is
  begin
    self.print_text('</testExecutions>');
  end;

end;
/
