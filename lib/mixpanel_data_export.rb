# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.


# ---------- Mixpanel Data Export ----------

=begin
 This Ruby file is the single require you can start off with in any other Ruby
 file that needs the Mixpanel data export functionality. We setup looking for
 gems in our local bundle that are required by this project, as well as requiring
 the key modules and classes of this project.
=end

# ---------- Require ----------

# Per Bundler.io documentation, the next two require directives MUST go before anything else.
# This is how every other Ruby file loaded in this project hereafter, will be able to source
# all of its needs from the locally bundled rubygems directory (/vendor/bundle).
require 'rubygems'
require 'bundler/setup'

# Run loadpath setup utility to include all lib sub-folders, automatically:
require "#{File.dirname(__FILE__)}/util/loadpath_setup"

# Ruby and rubygem libraries:
require 'digest/md5'
require 'json' unless defined?(JSON)

# Project libraries:
require 'util/logging_setup'
require 'util/connection'
require 'mixpanel/service'
require 'mixpanel/exporter'


# ---------- Testing: Start the Download ----------

# Uncomment the two lines below if you would like to run
# this data export system. Comment them back up if you are
# running rspec tests.

exporter = Mixpanel::Exporter.new
exporter.start
