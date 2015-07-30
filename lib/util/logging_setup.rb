# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.


require 'logging'
require_relative 'exporter_config'

# ---------- Location ----------

# Set the output directory where we will write log files to.
output_directory = Util::ExporterConfig.new.output_directory
date_segment = Time.now.strftime('%Y-%m-%d')
logfile = "export.#{date_segment}.log"
logfile_dir = File.expand_path(File.join(output_directory, 'logs'))
logfile_path = File.join(logfile_dir, logfile)

# For the logfile directory to be created, if necessary.
FileUtils::mkdir_p logfile_dir unless File.exists? logfile_dir



# ---------- Verbosity: Global ----------

# Set the global default logging verbosity level.
# Your options are one of the following:
#   :debug
#   :info
#   :warn
#   :error
#   :fatal
Logging.logger.root.level = :info



# ---------- Verbosity: Customized ----------

# Optional: We can setting log levels for individual Ruby classes in this project.
# To do so, uncomment and customize the example below. Be sure to reference the class
# fully qualified by module and as a String, and not a real constant. This allows us 
# to customize individual loggers not yet encountered in code whose class symbols we
# don't even yet know.

# Logging.logger['Appstronomy::Connection'].level = :debug
# Logging.logger['Mixpanel::Service'].level = :debug



# ---------- Formatting ----------

# Formatting Colors
# Additional examples here: https://github.com/TwP/logging/blob/master/examples/colorization.rb
# This will setup a color scheme called 'bright', which only makes sense for console
# based appenders, and which we'll use for the 'stdout' appender we define below.
Logging.color_scheme('bright',
                     levels: {
                         debug: :grey,
                         info: :green,
                         warn: :yellow,
                         error: :red,
                         fatal: [:white, :on_red]
                     },
                     date: :blue,
                     logger: :cyan,
                     message: :magenta)


# Formatting Patterns
# More pattern documentation at: https://github.com/TwP/logging/blob/master/lib/logging/layouts/pattern.rb

# Entry Pattern: We'll skip method name and line numbers, b/c turning on 'trace' with this logging gem is
# both confusing and impacts performance.
log_entry_pattern = '[%d] %-5l %c: %m\n'

# Date Pattern: We'll use a pattern similar to ISO8601, but without the middle 'T',
# so as to be more human readable.
log_date_pattern = '%Y-%m-%d %H:%M:%S'


# Formatting Layouts
basic_options = {date_pattern: log_date_pattern, pattern: log_entry_pattern}
file_layout = Logging.layouts.pattern(basic_options)
stdout_layout = Logging.layouts.pattern(basic_options.merge(color_scheme: 'bright'))



# ---------- Appenders ----------

file_appender = Logging.appenders.file(logfile_path, layout: file_layout)
stdout_appender = Logging.appenders.stdout(layout: stdout_layout)
Logging.logger.root.add_appenders(file_appender, stdout_appender)
