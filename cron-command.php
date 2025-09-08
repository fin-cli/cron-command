<?php

if ( ! class_exists( 'WP_CLI' ) ) {
	return;
}

$fpcli_cron_autoloader = __DIR__ . '/vendor/autoload.php';
if ( file_exists( $fpcli_cron_autoloader ) ) {
	require_once $fpcli_cron_autoloader;
}

WP_CLI::add_command( 'cron', 'Cron_Command' );
WP_CLI::add_command( 'cron event', 'Cron_Event_Command' );
WP_CLI::add_command( 'cron schedule', 'Cron_Schedule_Command' );
