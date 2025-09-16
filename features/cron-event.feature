Feature: Manage WP Cron events

  Background:
    Given a WP install

  # Fails on FinPress 4.9 because `fin cron event run --due-now`
  # executes the "fin_privacy_delete_old_export_files" event there.
  @require-fin-5.0
  Scenario: --due-now with supplied events should only run those
    # WP throws a notice here for older versions of core.
    When I try `fin cron event run --all`
    Then STDOUT should contain:
      """
      Success: Executed a total of
      """

    When I run `fin cron event run --due-now`
    Then STDOUT should contain:
      """
      Executed a total of 0 cron events
      """

    When I run `fin cron event schedule fin_cli_test_event_1 now hourly`
    Then STDOUT should contain:
      """
      Success: Scheduled event with hook 'fin_cli_test_event_1'
      """

    When I run `fin cron event schedule fin_cli_test_event_2 now hourly`
    Then STDOUT should contain:
      """
      Success: Scheduled event with hook 'fin_cli_test_event_2'
      """

    When I run `fin cron event run fin_cli_test_event_1 --due-now`
    Then STDOUT should contain:
      """
      Executed the cron event 'fin_cli_test_event_1'
      """
    And STDOUT should contain:
      """
      Executed a total of 1 cron event
      """

    When I run `fin cron event run --due-now --exclude=fin_cli_test_event_2`
    Then STDOUT should contain:
      """
      Executed a total of 0 cron events
      """

    When I run `fin cron event run fin_cli_test_event_2 --due-now`
    Then STDOUT should contain:
      """
      Executed the cron event 'fin_cli_test_event_2'
      """
    And STDOUT should contain:
      """
      Executed a total of 1 cron event
      """

  @require-fin-4.9.0
  Scenario: Unschedule cron event
    When I run `fin cron event schedule fin_cli_test_event_1 now hourly`
    And I try `fin cron event unschedule fin_cli_test_event_1`
    Then STDOUT should contain:
      """
      Success: Unscheduled 1 event for hook 'fin_cli_test_event_1'.
      """

    When I run `fin cron event schedule fin_cli_test_event_2 now hourly`
    And I run `fin cron event schedule fin_cli_test_event_2 '+1 hour' hourly`
    And I try `fin cron event unschedule fin_cli_test_event_2`
    Then STDOUT should contain:
      """
      Success: Unscheduled 2 events for hook 'fin_cli_test_event_2'.
      """

    When I try `fin cron event unschedule fin_cli_test_event`
    Then STDERR should be:
      """
      Error: No events found for hook 'fin_cli_test_event'.
      """

  Scenario: Run cron event with a registered shutdown function
    Given a fin-content/mu-plugins/setup_shutdown_function.php file:
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

    When I run `fin cron event schedule mycron now`
    And I try `fin cron event run --due-now`
    Then STDOUT should contain:
      """
      MY SHUTDOWN FUNCTION
      """

  Scenario: Run cron event with a registered shutdown function that logs to a file
    Given a fin-content/mu-plugins/setup_shutdown_function_log.php file:
      """
      <?php
      add_action('mycronlog', function() {
        breakthings();
      });

      register_shutdown_function(function() {
        error_log('LOG A SHUTDOWN FROM ERROR');
      });
      """

    And I run `fin config set WP_DEBUG true --raw`
    And I run `fin config set WP_DEBUG_LOG '{RUN_DIR}/server.log'`

    When I try `fin cron event schedule mycronlog now`
    And I try `fin cron event run --due-now`
    Then STDERR should contain:
      """
      Call to undefined function breakthings()
      """
    And the {RUN_DIR}/server.log file should exist
    And the {RUN_DIR}/server.log file should contain:
      """
      LOG A SHUTDOWN FROM ERROR
      """
