# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.


module Util

  # Handles general configuration for this Mixpanel Data Export project (broadly)
  # and more specifically, for the {Mixpanel::Exporter} class that handles writing
  # exported event data to CSV files on the file system.
  #
  # Our main purpose is to load configuration information, such as the base output directory
  # in which to write log files and CSV files.
  #
  # @author Sohail Ahmed, https://github.com/idStar
  class ExporterConfig

    # The contents of the config file this class is responsible for loading.
    attr_reader :config_info


    # Generates a new instance with and has it load our configuration immediately.
    def initialize
      configure_logging
      load_configuration
    end


    # Retrieves the output directory under which logging and date specific folders
    # would be created.
    #
    # @return [String] The path for where this utility should output content to.
    def output_directory
      @config_info['Output Directory']
    end


    # Retrieves the number of days back the Mixpanel event history query should
    # be asked for. Defaults to 1 if not specified.
    #
    # @return [Fixnum] The number of days back the export should start from.
    def from_days_ago
      @config_info['From Days Ago'] || 1
    end


    # Retrieves the number of days back the Mixpanel event history query should
    # end at. Defaults to 0 if not specified, which means retrieve up to the latest
    # available data.
    #
    # @return [Fixnum] The number of days back the export should end at.
    def to_days_ago
      @config_info['To Days Ago'] || 0
    end


    # Retrieves whether or not we should be saving downloaded files into folders
    # based on the date they were run. Defaults to false.
    #
    # @return [Boolean] Whether sub-folders should be created by date.
    def create_subfolders_by_date?
      @config_info['Create Sub-folders by Date']
    end


    # Retrieves whether or not we should name downloaded files with the date range
    # of the contained events. Defaults to true. If you set this to false, we will
    # name files based on the date they were downloaded (which may have little to no
    # bearing on when the contained events actually took place).
    #
    # If you set this to true, the actual dates implied by from_days_ago and to_days_ago
    # will both show up in your downloaded file's name, even if they are the same.
    #
    # @return [Boolean] Whether event date ranges should be used in naming files.
    def use_event_dates_in_filenames?
      @config_info['Use Event Dates in Filenames']
    end


    # Optional. The array of event names for exclusion. Applied before
    # `events_to_include` is consulted.
    # Only use the exclude or include list; don't use both.
    #
    # @return [Array] Of event names.
    def events_to_exclude
      @config_info['Events to Exclude']
    end


    # Optional. The array of event names for inclusion. Applied after
    # `events_to_exclude` is consulted. Only if `events_to_exclude`
    # is an empty array is this list consulted.
    # Only use the exclude or include list; don't use both.
    #
    # @return [Array] Of event names.
    def events_to_include
      @config_info['Events to Include']
    end


    # Whether or not to scale request expiry based on how long the date
    # range is. Longer date spans will receive longer expiry durations.
    #
    # @return [Boolean] Whether to scale request expiry duration.
    def scale_request_expiry
      @config_info['Scale Request Expiry']
    end


    # When `scale_request_expiry` is set to true, we'll multiply the number
    # of days in the request range by this number to arrive at the expiry duration.
    # Note however, that we will apply a minimum duration when scaling is in effect, so that
    # request for one or two days of data don't prematurely timeout.
    #
    # @return [Float] The number of seconds. Might be fractional.
    def scale_request_seconds_per_day
      @config_info['Scale Request Seconds Per Day']
    end


    # When `scale_request_expiry` is set to false, we'll set the window of
    # time that any request is valid, to exactly this value.
    #
    # @return [Fixnum] The number of seconds.
    def unscaled_request_expiry_seconds
      @config_info['Unscaled Request Expiry Duration in Seconds']
    end


    # When `scale_request_expiry` is set to true, we'll cap the window of
    # time that any request is valid, to this maximum.
    #
    # @return [Fixnum] The number of seconds.
    def max_scaled_request_expiry_seconds
      @config_info['Maximum Scaled Request Expiry Duration in Seconds']
    end


    # Loads our `Exporter.config.json` file to set the {#output_directory} instance variable.
    # @return [void]
    def load_configuration
      file_path = File.expand_path(File.join(__dir__, '../../config/Exporter.config.json'))
      @logger.info "Loading Exporter configuration file from path: '#{file_path}'"

      unless File.exists? file_path
        @logger.fatal "Could not find file 'Exporter.config.json' at path '#{file_path}'. \
              We need this location defined in order to know where to place downloaded data."
        exit!
      end

      file = File.read(file_path)
      @config_info = JSON.parse(file)
      @logger.debug "Parsed configuration file with contents: #{@config_info.inspect}"
    end


    private

    # Sets up our logging instance attribute, with a logger for this class.
    # By default, this class specific logger inherits settings from the root logger.
    # @return [void]
    def configure_logging
      @logger = Logging.logger[self]
    end

  end
end