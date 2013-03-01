# We want to support ActiveSupport 2.3 on Ruby 1.9, so we need to make some patches.
# Load this only for running tests on Ruby 1.9 (instead of having mongo_mapper patch it), as any
# Rails 2.3 application that wants to run on Ruby 1.9 must make a patch like that by itself.
#
# The patch below is taken from the UserVoice developer blog. Many thanks!
# http://developer.uservoice.com/entries/how-to-upgrade-a-rails-2.3.14-app-to-ruby-1.9.3/

# TZInfo needs to be patched.  In particular, you'll need to re-implement the datetime_new! method:
require 'tzinfo'

module TZInfo
  # Methods to support different versions of Ruby.
  module RubyCoreSupport #:nodoc:
    # Ruby 1.8.6 introduced new! and deprecated new0.
    # Ruby 1.9.0 removed new0.
    # Ruby trunk revision 31668 removed the new! method.
    # Still support new0 for better performance on older versions of Ruby (new0 indicates
    # that the rational has already been reduced to its lowest terms).
    # Fallback to jd with conversion from ajd if new! and new0 are unavailable.
    if DateTime.respond_to? :new!
      def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
        DateTime.new!(ajd, of, sg)
      end
    elsif DateTime.respond_to? :new0
      def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
        DateTime.new0(ajd, of, sg)
      end
    else
      HALF_DAYS_IN_DAY = rational_new!(1, 2)

      def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
        # Convert from an Astronomical Julian Day number to a civil Julian Day number.
        jd = ajd + of + HALF_DAYS_IN_DAY

        # Ruby trunk revision 31862 changed the behaviour of DateTime.jd so that it will no
        # longer accept a fractional civil Julian Day number if further arguments are specified.
        # Calculate the hours, minutes and seconds to pass to jd.

        jd_i = jd.to_i
        jd_i -= 1 if jd < 0
        hours = (jd - jd_i) * 24
        hours_i = hours.to_i
        minutes = (hours - hours_i) * 60
        minutes_i = minutes.to_i
        seconds = (minutes - minutes_i) * 60

        DateTime.jd(jd_i, hours_i, minutes_i, seconds, of, sg)
      end
    end
  end
end
