## harvest_report

Harvert reports for non-admin harvest users

## Installation

    gem install harvest_report

## Usage

    Usage: harvest_report [OPTIONS]
        --email EMAIL                your harvest email
        --password PASSWORD          your harvest password
        --domain DOMAIN              harvest domain
        --start-date START_DATE      report start date (e.g 2012-01-01)
        --stop-date STOP_DATE        report stop date (e.g 2012-01-31)
        --directory DIRECTORY        reports directory (default /tmp/harvest_report)
    -h, --help                       Show this message

## Example

    $ harvest_report --email bob@example.com --password qwerty --domain mycompany --start-date 2012-01-01 --stop-date 2012-01-31
