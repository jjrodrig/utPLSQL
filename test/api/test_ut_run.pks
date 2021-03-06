create or replace package test_ut_run is
  --%suite(ut.run)
  --%suitepath(utplsql.api)


  --%test(ut.version() returns version of the framework)
  procedure ut_version;

  --%test(ut.fail() marks test as failed)
  procedure ut_fail;

  procedure create_ut3$user#_tests;
  procedure drop_ut3$user#_tests;

  --%context(ut_run_procedure)
  --%displayname(ut.run() procedure options)
  --%beforeall(create_ut3$user#_tests)
  --%afterall(drop_ut3$user#_tests)

  --%test(Runs all tests in current schema with default reporter when no parameters given)
  procedure run_proc_no_params;
  --%test(Runs all tests in current schema with specified reporter)
  procedure run_proc_specific_reporter;
  --%test(Runs all tests in current schema with coverage file list)
  procedure run_proc_cov_file_list;

  --%test(Runs given package only with package name given as path)
  procedure run_proc_pkg_name;
  --%test(Runs all from given package with package name given as path and coverage file list)
  procedure run_proc_pkg_name_file_list;
  --%test(Runs tests from given paths only with paths list)
  procedure run_proc_path_list;
  --%test(Runs tests from given paths only with paths list and coverage file list)
  procedure run_proc_path_list_file_list;
  --%test(Runs all tests in current schema using default reporter when null reporter given)
  procedure run_proc_null_reporter;
  --%test(Runs all tests in current schema with null path provided)
  procedure run_proc_null_path;
  --%test(Runs all tests in current schema with null path list given)
  procedure run_proc_null_path_list;
  --%test(Runs all tests in current schema with empty path list given)
  procedure run_proc_empty_path_list;

  procedure create_suite_with_commit;
  procedure drop_suite_with_commit;
  --%test(Reports a warning if transaction was invalidated by test with automatic rollback)
  --%beforetest(create_suite_with_commit)
  --%aftertest(drop_suite_with_commit)
  procedure run_proc_warn_on_commit;


  procedure create_failing_beforeall_suite;
  procedure drop_failing_beforeall_suite;
  --%test(Marks child suite as failed when parent's suite beforeall fails)
  --%beforetest(create_failing_beforeall_suite)
  --%aftertest(drop_failing_beforeall_suite)
  procedure run_proc_fail_child_suites;

  --%endcontext

  --%context(run_proc_transaction_control)

  --%beforeall
  procedure transaction_setup;
  --%afterall
  procedure transaction_cleanup;
  --%test(Leaves transaction open and uncommitted with a_force_manual_rollback)
  procedure run_proc_keep_test_data;
  --%test(Leaves transaction open and uncommitted with a_force_manual_rollback with exceptions)
  procedure run_proc_keep_test_data_raise;
  --%test(Does not impact current transaction when ran without a_force_manual_rollback)
  procedure run_proc_discard_test_data;

  --%endcontext


  --%context(ut_run_function)
  --%displayname(ut.run() function options)
  --%beforeall(create_ut3$user#_tests)
  --%afterall(drop_ut3$user#_tests)

  --%test(Runs all tests in current schema with default reporter when no parameters given)
  procedure run_func_no_params;
  --%test(Runs all tests in current schema with specified reporter)
  procedure run_func_specific_reporter;
  --%test(Runs all tests in current schema with coverage file list)
  procedure run_func_cov_file_list;

  --%test(Runs given package only with package name given as path)
  procedure run_func_pkg_name;
  --%test(Runs all from given package with package name given as path and coverage file list)
  procedure run_func_pkg_name_file_list;
  --%test(Runs tests from given paths with paths list)
  procedure run_func_path_list;
  --%test(Runs tests from given paths with paths list and coverage file list)
  procedure run_func_path_list_file_list;
  --%test(Runs all tests in current schema using default reporter when null reporter given)
  procedure run_func_null_reporter;
  --%test(Runs all tests in current schema with null path provided)
  procedure run_func_null_path;
  --%test(Runs all tests in current schema with null path list given)
  procedure run_func_null_path_list;
  --%test(Runs all tests in current schema with empty path list given)
  procedure run_func_empty_path_list;
  --%test(Runs all tests in current schema with coverage file list and default reporter)
  procedure run_func_cov_file_lst_null_rep;
  --%test(Executes successfully an empty suite)
  procedure run_func_empty_suite;

  --disabled(Makes session wait for lock on 18.1 due to library cache pin wait)
  --%test(ut.run - raises after completing all tests if a test fails with ORA-04068 or ORA-04061)
  --%beforetest(create_test_suite)
  --%aftertest(drop_test_suite)
  procedure raise_in_invalid_state;
  procedure create_test_suite;
  procedure drop_test_suite;

  --%test(ut.run - Does not execute suite when specified package is not valid)
  --%beforetest(compile_invalid_package)
  --%aftertest(drop_invalid_package)
  procedure run_in_invalid_state;
  procedure compile_invalid_package;
  procedure drop_invalid_package;

  --%test(Invalidate package specs via rebuild but still execute package)
  --%beforetest(generate_invalid_spec)
  --%aftertest(drop_invalid_spec)
  procedure run_and_revalidate_specs;
  procedure generate_invalid_spec;
  procedure drop_invalid_spec;

  --%test(Provides warnings on invalid annotations)
  --%beforetest(create_bad_annot)
  --%aftertest(drop_bad_annot)
  procedure run_and_report_warnings;
  procedure create_bad_annot;
  procedure drop_bad_annot;
  --%endcontext

end;
/
