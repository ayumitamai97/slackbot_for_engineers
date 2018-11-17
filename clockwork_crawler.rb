require "clockwork"
require "active_support/all"
require_relative "seminar"

include Clockwork

every(1.day, 'notify_slack', :at => '0:00') { Seminar.new.get_connpass_info }
