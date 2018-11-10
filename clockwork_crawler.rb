require "clockwork"
require "active_support/all"
require_relative "seminar"

include Clockwork

handler do |job|
  Seminar.new.get_connpass_info
end

every(1.day, 'notify_slack', :at => '23:00')
