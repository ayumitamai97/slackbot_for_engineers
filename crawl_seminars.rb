require "json"
require "net/http"
require "date"
require "clockwork"
require "active_support/all"
require "pry"
require_relative "slack"

class Seminar
  include Slack

  REGIONS = %w(東京 大阪 福岡)
  SEARCH_START_POSITIONS = %w(1 101).freeze
  def get_connpass_info
    REGIONS.each do |region|
      post_message("#{region}で1週間以内に開催される、人気(残席2割未満)のイベントをお知らせします :full_moon_with_face:")

      SEARCH_START_POSITIONS.each do |position|
        encoded_uri =
          URI.encode("https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=#{position}")

        uri = URI.parse(encoded_uri)
        json = JSON.parse Net::HTTP.get_response(uri).body
        notify_slack(json: json)
      end
    end
  end

  def get_spzcolab_info
    # だれかやって！
  end

  private
  def notify_slack(json:)
    events = json["events"]
    events.each do |event|
      parse_connpass_info(event)
      next if @waiting_count > 0 || @limit_count == 0
      post_message("*" + @event_title + "* by " + @event_owner + "\n" + @event_url)
    end
  end

  def parse_connpass_info(event)
    @event_url = event["event_url"]
    @event_title = event["title"]
    @waiting_count = event["waiting"].to_i
    @limit_count = event["limit"].to_i
    @accepted_count = event["accepted"].to_i
    @event_owner =
      event["series"] ? event["series"]["title"] : event["owner_display_name"]
  end

  def dates
    today = Date.today
    (1..7).map{ |day| (today + day).to_s.gsub("-","") }.join(",")
  end
end

include Clockwork

handler do |job|
  Seminar.new.get_connpass_info
end

# every(1.day, 'notify_job', :at => '23:00')
every(1.minute, 'notify_slack.job')
