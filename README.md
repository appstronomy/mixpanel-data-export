# Mixpanel Data Export 
This tool has been written in Ruby and packaged as a project.  It is not a single script but rather, a set of utilities that work together to provide data export functionality. It is a means for exporting all of your event data from Mixpanel using their published API.

Note that while this tool was designed to help you export your event data from Mixpanel, it was not built by Mixpanel. 

*All instructions that follow assume that you are in the project's root directory.
*
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
  "To Days Ago": 0
}
```

The `From Days Ago` is for how many days back the **start** of the export range is.

The `To Days Ago` is for how many days back the **end** of the export range is.

The recommended configuration is to use the defaults shown above, where you are always retrieving *yesterday's* data. 

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

A new directory is created for each day that the script is run. For example, if you run the script on July 30, 2016, you'll see a directory created with the name '2016-07-30'.

A sibling directory is also created if need be, called 'logs'. Each day's run appends to a dated log file. 

Similarly, the CSV files generated will always use today's date. Each event creates its own CSV file with data for just that event. If no data was downloaded for a particular event, then no CSV file is created for that event.

## Programmer Documentation
You can find module and class documentation in the `/doc` folder. Point your browser to the `index.html` file to get started.

To regenerate the documentation, make sure you have the `yard` gem installed, and then from the root of this project, issue the `yardoc` command.

## Troubleshooting

If you have any issues installing the gems via Bundler, you can try using Ruby 2.1.2, which was used to successfully compile finicky gems like Red Carpet on a Mac.

## Changelog

See the Changelog for a history of release notes.

## Collaborators and Maintainers

Contributors

##Copyright

Copyright (c) 2015+ Appstronomy, LLC. See [license] for details.
