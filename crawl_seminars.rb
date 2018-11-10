require "json"
require "net/http"
require "date"
require 'clockwork'
require 'active_support/all'

class Slack
  def post(text)
    Net::HTTP.post_form(
      URI.parse('https://slack.com/api/chat.postMessage'),
      {
        "token" => ENV["SLACK_BOT_TOKEN"],
        # "channel"=> ENV["SLACK_BOT_CHANNEL"],
        "channel"=> "DDDV4897G", # テスト用
        "text"=> text
      })
  end
end

class Seminar
  REGIONS = %w(東京 大阪 福岡)
  def get_connpass_info
    REGIONS.each do |region|
      slack = Slack.new
      slack.post("#{region}で1週間以内に開催される、人気(残席2割未満)のイベントをお知らせします :full_moon_with_face:")

      uris =
        [URI.parse(URI.encode "https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=1"),
          URI.parse(URI.encode "https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=101")]
  
      uris.each do |uri|
        json = JSON.parse Net::HTTP.get_response(uri).body
        parse_connpass_info(json)
      end
    end
  end

  def get_spzcolab_info
    # だれかやって！
  end

  private
  def parse_connpass_info(json)
    events = json["events"]

    events.each do |event|
      event_url = event["event_url"]
      event_title = event["title"]
      waiting_count = event["waiting"].to_i
      limit_count = event["limit"].to_i
      accepted_count = event["accepted"].to_i
      event_owner = event["series"]["title"] unless event["series"].nil?

      next if waiting_count > 0 || limit_count == 0

      if accepted_count / limit_count > 0.8 && !event_owner.nil?
        slack.post("*" + event_title + "* by " + event_owner + "\n" + event_url)

      elsif accepted_count / limit_count > 0.8 && event_owner.nil?
        event_owner = event["owner_display_name"]
        slack.post("*" + event_title + "* by " + event_owner + "\n" + event_url)
      end
    end
  end
  def dates
    today = Date.today
    dates_arr = []

    for num in 1..7
      dates_arr << (today + num).to_s.gsub("-","")
    end

    dates_arr.join(",")
  end
end




include Clockwork

handler do |job|
  Seminar.new.get_connpass_info
end

# every(1.day, 'notify_slack.job', :at => '23:00')
every(1.minute, 'notify_slack.job')
