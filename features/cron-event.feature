Feature: Manage WP Cron events

  Background:
    Given a WP install

  # Fails on FinPress 4.9 because `fp cron event run --due-now`
  # executes the "fp_privacy_delete_old_export_files" event there.
  @require-fp-5.0
  Scenario: --due-now with supplied events should only run those
    # WP throws a notice here for older versions of core.
    When I try `fp cron event run --all`
    Then STDOUT should contain:
      """
      Success: Executed a total of
      """

    When I run `fp cron event run --due-now`
    Then STDOUT should contain:
      """
      Executed a total of 0 cron events
      """

    When I run `fp cron event schedule fp_cli_test_event_1 now hourly`
    Then STDOUT should contain:
      """
      Success: Scheduled event with hook 'fp_cli_test_event_1'
      """

    When I run `fp cron event schedule fp_cli_test_event_2 now hourly`
    Then STDOUT should contain:
      """
      Success: Scheduled event with hook 'fp_cli_test_event_2'
      """

    When I run `fp cron event run fp_cli_test_event_1 --due-now`
    Then STDOUT should contain:
      """
      Executed the cron event 'fp_cli_test_event_1'
      """
    And STDOUT should contain:
      """
      Executed a total of 1 cron event
      """

    When I run `fp cron event run --due-now --exclude=fp_cli_test_event_2`
    Then STDOUT should contain:
      """
      Executed a total of 0 cron events
      """

    When I run `fp cron event run fp_cli_test_event_2 --due-now`
    Then STDOUT should contain:
      """
      Executed the cron event 'fp_cli_test_event_2'
      """
    And STDOUT should contain:
      """
      Executed a total of 1 cron event
      """

  @require-fp-4.9.0
  Scenario: Unschedule cron event
    When I run `fp cron event schedule fp_cli_test_event_1 now hourly`
    And I try `fp cron event unschedule fp_cli_test_event_1`
    Then STDOUT should contain:
      """
      Success: Unscheduled 1 event for hook 'fp_cli_test_event_1'.
      """

    When I run `fp cron event schedule fp_cli_test_event_2 now hourly`
    And I run `fp cron event schedule fp_cli_test_event_2 '+1 hour' hourly`
    And I try `fp cron event unschedule fp_cli_test_event_2`
    Then STDOUT should contain:
      """
      Success: Unscheduled 2 events for hook 'fp_cli_test_event_2'.
      """

    When I try `fp cron event unschedule fp_cli_test_event`
    Then STDERR should be:
      """
      Error: No events found for hook 'fp_cli_test_event'.
      """

  Scenario: Run cron event with a registered shutdown function
    Given a fp-content/mu-plugins/setup_shutdown_function.php file:
      """
      add_action('mycron', function() {
        breakthings();
      });

      register_shutdown_function(function() {
        $error = error_get_last();
        if ($error['type'] === E_ERROR) {
          WP_CLI::line('MY SHUTDOWN FUNCTION');
        }
        });
      """

    When I run `fp cron event schedule mycron now`
    And I try `fp cron event run --due-now`
    Then STDOUT should contain:
      """
      MY SHUTDOWN FUNCTION
      """

  Scenario: Run cron event with a registered shutdown function that logs to a file
    Given a fp-content/mu-plugins/setup_shutdown_function_log.php file:
      """
      <?php
      add_action('mycronlog', function() {
        breakthings();
      });

      register_shutdown_function(function() {
        error_log('LOG A SHUTDOWN FROM ERROR');
      });
      """

    And I run `fp config set WP_DEBUG true --raw`
    And I run `fp config set WP_DEBUG_LOG '{RUN_DIR}/server.log'`

    When I try `fp cron event schedule mycronlog now`
    And I try `fp cron event run --due-now`
    Then STDERR should contain:
      """
      Call to undefined function breakthings()
      """
    And the {RUN_DIR}/server.log file should exist
    And the {RUN_DIR}/server.log file should contain:
      """
      LOG A SHUTDOWN FROM ERROR
      """
