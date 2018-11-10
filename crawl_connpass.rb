# NEEDS REFACTORING !!!!!

require "json"
require "net/http"
require "date"
require 'clockwork'
require 'active_support/all'

def notify_slack
  %w(東京 大阪 福岡).each do |region|
    Net::HTTP.post_form(
      URI.parse('https://slack.com/api/chat.postMessage'),
      {
        "token" => ENV["SLACK_BOT_TOKEN"],
        "channel"=> ENV["SLACK_BOT_CHANNEL"],
        "text"=> "#{region}で1週間以内に開催される、人気(残席2割未満)のイベントをお知らせします :full_moon_with_face:"
      })

    today = Date.today
    dates_arr = []

    for num in 1..7
      dates_arr << (today + num).to_s.gsub("-","")
    end

    dates = dates_arr.join(",")

    uris =
      [URI.parse(URI.encode "https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=1"),
        URI.parse(URI.encode "https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=101")]

    uris.each do |uri|
      json = JSON.parse Net::HTTP.get_response(uri).body

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
          Net::HTTP.post_form(
            URI.parse('https://slack.com/api/chat.postMessage'),
            {
              "token" => ENV["SLACK_BOT_TOKEN"],
              "channel"=> ENV["SLACK_BOT_CHANNEL"],
              "text"=> "*" + event_title + "* by " + event_owner + "\n" + event_url
            })
        elsif accepted_count / limit_count > 0.8 && event_owner.nil?
          event_owner = event["owner_display_name"]
          Net::HTTP.post_form(
            URI.parse('https://slack.com/api/chat.postMessage'),
            {
              "token" => ENV["SLACK_BOT_TOKEN"],
              "channel"=> ENV["SLACK_BOT_CHANNEL"],
              "text"=> "*" + event_title + "* by " + event_owner + "\n" + event_url
            })
        end
      end
    end
  end
end


include Clockwork

handler do |job|
  notify_slack
end

every(1.day, 'notify_slack.job', :at => '16:09')
