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