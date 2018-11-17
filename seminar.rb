require "json"
require "net/http"
require "date"
require_relative "slack"

class Seminar
  include Slack

  REGIONS = %w(東京 大阪 福岡)
  SEARCH_START_POSITIONS = %w(1 101).freeze
  def get_connpass_info
    REGIONS.each do |region|
      @message = region + "で1週間以内に開催される、人気(残席2割未満)のイベントをお知らせします :full_moon_with_face: \n"

      SEARCH_START_POSITIONS.each do |position|
        encoded_uri =
          URI.encode("https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&start=#{position}")

        uri = URI.parse(encoded_uri)
        json = JSON.parse Net::HTTP.get_response(uri).body
        notify_slack(json: json, message: @message, position: position)
      end
    end

    # ENV["SLACK_MY_USER_ID"] のフォーマットは <@ABCDEFG12>
    # Slack User ID はこれで確認できる: https://slack.com/api/users.list?token=YOUR_TOKEN
    post_message("ご意見・ご感想は " + ENV["SLACK_MY_USER_ID"] + " まで :raised_hands:")
  end

  def get_spzcolab_info
    # だれかやって！
  end

  private
  def notify_slack(json:, message:, position:)
    events = json["events"]
    @post_count = 0
    @message = search_from_most_recent?(position) ? message : ""

    events.each do |event|
      parse_connpass_info(event)
      next if @waiting_count >= 0 || @limit_count == 0
      next if @accepted_count / @limit_count < 0.8
      @post_count += 1
      @message += "*" + @event_title + "* by " + @event_owner + "\n" + @event_url + "\n"
    end

    @message += "該当のイベントはありませんでした…。" if
      @post_count == 0 && search_from_most_recent?(position)
    post_message(@message)
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

  def search_from_most_recent?(position)
    position.to_i == 1
  end
end
