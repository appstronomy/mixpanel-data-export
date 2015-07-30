# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.


# Include our lib folder and all of its sub-folders in the
# Ruby $LOAD_PATH. This way, all of our own require statements
# can be simply stated.
current_dir = File.dirname(__FILE__)
libdir = File.expand_path(File.join(current_dir, '..'))
#puts "Including all subdirectories in $LOAD_PATH of lib directory: #{libdir}"
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

Dir.glob('**/*/').each do | relative_subdir |
  subdir = File.join(libdir, relative_subdir)
  $LOAD_PATH.unshift(subdir) unless $LOAD_PATH.include?(subdir)
end
