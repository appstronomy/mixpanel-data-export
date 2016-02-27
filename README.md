# Mixpanel Data Export 
This tool has been written in Ruby and packaged as a project.  It is not a single script but rather, a set of utilities that work together to provide data export functionality. It is a means for exporting all of your event data from Mixpanel using their published API.

Note that while this tool was designed to help you export your event data from Mixpanel, it was not built by Mixpanel. 

_All instructions that follow assume that you are in the project's root directory._

## Installation

You should have Ruby 2.x installed, as well as Rubygems, including the Bundler gem. For help installing Ruby on your system, see [the official Ruby installation page](https://www.ruby-lang.org/en/documentation/installation/). For help with installing RubyGems, see [RubyGems Basics](http://guides.rubygems.org/rubygems-basics/).

You'll then use [Bundler](http://bundler.io) to install the gems used by this project by issuing the command:

`bundle install`

Next, you'll copy the config files bundled as templates, removing the `.template` token in your copy. These files are located in the project's `config` folder.

* Exporter.config.*template*.json → Exporter.config.json
* SSL.config.*template*.json → SSL.config.json
* MixpanelCredentials.config.*template*.json → MixpanelCredentials.config.json

## Configuration

Before you can run the script, you need to configure the three JSON files you just made copies of.

#### File: Exporter.config.json

In this file, you specify in which directory the download-generated CSV files should be placed, using the entry `Output Directory`.

You also specify the range of days in which data should be fetched from Mixpanel.

```
{
  "Output Directory": "~/Desktop/App Output/Mixpanel Export",
  "From Days Ago": 1,
  "To Days Ago": 0,
  "Create Sub-folders by Date": false,
  "Use Event Dates in Filenames" : true,
  "Events to Exclude" : ["Data Imported", "Notification Received"],
  "Events to Include" : [],
  "Scale Request Expiry" : true,
  "Scale Request Seconds Per Day" : 1.3,
  "Unscaled Request Expiry Duration in Seconds" : 80,
  "Maximum Scaled Request Expiry Duration in Seconds" : 200
}
```

The `From Days Ago` is for how many days back the **start** of the export range is.

The `To Days Ago` is for how many days back the **end** of the export range is.

The `Create Sub-folders by Date` takes a boolean value. We recommend setting this to `false`, so that all of the event data across multiple dates, sits inside a single folder. If you do set this to `true`, then files we be placed in subfolders named after the date of download.

The `Use Event Dates in Filenames` determines whether we use the date range of the events being downloaded, in the actual filenames of the downloaded event data. We recommend setting this to `true`. Doing so will give you filenames with both the start and end date in the filename. Setting this to `false` means that the only date in the filename will be the date that the file was downloaded.

The `Events to Exclude` is an optional array of the names of events that you do *not* want to be downloaded. If you provide a non-empty array here, we'll also ignore the value you set for the mutually exclusive property `Events to Include`.

The `Events to Include` is mutually exclusive with the property `Events to Exclude`. If you provide a non-empty array for this property, we'll *only* download those events.

The `Scale Request Expiry` has a Boolean setting. We recommend setting this to `true`. Doing so, allows us to scale the request expiry timeout to be proportionate to the number of days you are downloading data for. Asking for data spanning weeks or months will take longer than asking for data from just yesterday. We don't unilaterally set a high number for the request expiry, because doing so is a potential security risk; anyone else who sniffs the request URL could re-issue it to obtain your data. Mixpanel [tutorials](https://mixpanel.com/docs/api-documentation/a-tutorial-on-exporting-data) generally use 10 minutes (600 seconds). We err on the side of being more conservative.

The `Scale Request Seconds Per Day` lets you define how generous a timeout you desire, in a formulaic manner. For example, if you set this to 0.5 and issue a query spanning 200 days, you will then have set an expiry of 100 seconds. Note that the tool has a minimum request expiry duration of 30 seconds, since most requests, event for just a single day's worth of data, take several seconds.

The `Unscaled Request Expiry Duration in Seconds` is what the tool will consult if you set  `Scale Request Expiry` to `false`. It is an absolute number that will be used across the board for request expiry. If you go this route, we suggest using `60` seconds if you plan to make requests spanning less than a few days. For requests that can span months, you should use something closer to `400` seconds. The Mixpanel data export web service can be really slow when querying data older than a few days.

The `Maximum Scaled Request Expiry Duration in Seconds` is the cap we should apply to the request expiry duration when `Scale Request Expiry` is set to `true`. This protects the tool from inadvertently calculating an expiry duration into hours (creating a security risk). Instead, we'll always cap the request expiry duration at this value.

The recommended configuration is to use the defaults shown above for `From Days Ago` and `To Days Ago`, where you are always retrieving *yesterday's* data. 

Schedule this script to run daily, and you'll always download the latest data available, without any gaps in your collected data.

Should you need to, you can of course edit the date range in this file and export event data for a different span of time.

#### File: SSL.config.json

In order for this Mixpanel Data Export Tool tool to talk to Mixpanel's servers over SSL, we have to advise the tool on where it can find the bundle of root certificates from various Certificate Authorities.

On many systems, these are found in a file named `cacert.pem`. In the example below, the path used is for the OpenSSL bundled root certificates file.

This may be different on Windows and Linux systems.

```
{
  "certificate_authority": {
    "cert_file_path": "/usr/local/etc/openssl/certs/cacert.pem"
  }
}
```

For more information on root certificates, you may find this link helpful: [http://wiki.cacert.org/FAQ/ImportRootCert](http://wiki.cacert.org/FAQ/ImportRootCert).


#### File: MixpanelCredentials.config.json

This file is where you store your API credentials to access your data on Mixpanel.

The contents shown below are fake keys that don't actually work -- you need to provide your own.

```
{
  "API Key": "92a533a1284ee3012e31d2a3e7bff8da",
  "API Secret": "0a12345678f165a2312a72b9e4331288"
}
```

Per the Mixpanel documentation on their Data Export API:

> Note: your **api_key** and **api_secret** can be found in your [account](https://mixpanel.com/account/) menu within the Projects tab.


## Usage
It is recommended that you schedule this tool to run nightly. That way, you are at most, just one day away from having all the data that Mixpanel has collected.

`ruby ./lib/mixpanel_data_export.rb`

An illustration of what to expect when you run this command is below. Of course, your events will differ in name, number and quantity of data retrieved.

![usage example](https://github.com/appstronomy/mixpanel-data-export/blob/master/Mixpanel%20Data%20Export.gif)

## Output Files

If you set `Create Sub-folders by Date` to `true`, then a new directory is created for each day that the script is run. For example, if you run the script on July 30, 2016, you'll see a directory created with the name '2016-07-30'.

By default however, all files are dropped into your output directory, without any sub-folder segmentation.

A sub-directory of your output directory is also created if need be, called 'logs'. Each day's run appends to a dated log file. 

Each downloaded file contains the name of the event it holds data for.

If you set `Use Event Dates in Filenames` to `true`, then your downloaded event data will be named  with the date range reflecting the date range of the event data itself. If you set this to `false`, then the date of the download is what you'll find in the filename.

Each event creates its own CSV file with data for just that event. If no data was downloaded for a particular event, then no CSV file is created for that event.

The CSV file has columns sorted alphabetically, with the exception of the first column, which will always include the name of the event (the column is called *event*). The rest of the columns follow Ruby's standard sorting algorithm; special characters and numbers come first, then capital letters and then lower case letters.

## Development
### Programmer Documentation
You can find module and class documentation in the `/doc` folder. Point your browser to the `index.html` file to get started.

To regenerate the documentation, make sure you have the `yard` gem installed, and then from the root of this project, issue the `yardoc` command.

### Enhancements
Please open a new issue to discuss changes you'd like to make. We can coordinate before you make a pull request.

### To-do
This project does need unit tests. We only have placeholder files for [rspec](http://rspec.info/) based testing.

## Troubleshooting

If you have any issues installing the gems via Bundler, you can try using Ruby 2.1.2, which was used to successfully compile finicky gems like 'redcarpet' on a Mac.

## Changelog

See the [Changelog](https://github.com/appstronomy/mixpanel-data-export/blob/master/Changelog.md) for a history of release notes.

## Collaborators and Maintainers

See the [Contributors](https://github.com/appstronomy/mixpanel-data-export/graphs/contributors) page for details.

## Copyright 

Copyright (c) 2015-2016+ [Appstronomy](http://appstronomy.com/), LLC. See [license](https://github.com/appstronomy/mixpanel-data-export/blob/master/LICENSE.txt) for details.
