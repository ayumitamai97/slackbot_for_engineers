require "json"
require "net/http"
require "date"
require_relative "slack"

class Seminar
  include Slack
  REGIONS = %w(東京 大阪 福岡)

  def get_connpass_info
    REGIONS.each do |region|
      @message = region + "で1週間以内に開催される、人気(残席3割未満)のイベントをお知らせします :full_moon_with_face: \n"

      encoded_uri =
        URI.encode("https://connpass.com/api/v1/event/?keyword=#{region}&ymd=#{dates}&count=100&order=2")

      uri = URI.parse(encoded_uri)
      json = JSON.parse Net::HTTP.get_response(uri).body
      notify_slack(json: json, message: @message, region: region)
    end

    # ENV["SLACK_MY_USER_ID"] のフォーマットは <@ABCDEFG12>
    # Slack User ID はこれで確認できる: https://slack.com/api/users.list?token=YOUR_TOKEN
    post_message("ご意見・ご感想は " + ENV["SLACK_MY_USER_ID"] + " まで :raised_hands:")
  end

  def get_spzcolab_info
    # だれかやって！
  end


  private

  def notify_slack(json:, message:, region:)
    events = json["events"]
    @post_count = 0

    events.each do |event|
      parse_connpass_info(event)

      next unless @event_address.match?(/#{region}/)
      next if invalid_limit?(limit: @limit_count)
      next if too_popular_or_unpopular?(accepted: @accepted_count, limit: @limit_count)

      @post_count += 1
      @message += "*#{@event_title}* (#{@event_date})\n#{@event_url}\n"
    end

    @message += "該当のイベントはありませんでした…。" if @post_count == 0
    post_message(@message)
  end

  def parse_connpass_info(event)
    @event_url = event["event_url"]
    @event_title = event["title"]
    @waiting_count = event["waiting"].to_i
    @limit_count = event["limit"].to_i
    @accepted_count = event["accepted"].to_i
    @event_date = event["started_at"].to_date.to_s.gsub("-", "/")
    @event_address = event["address"]
  end

  def dates
    today = Date.today
    (1..7).map{ |day| (today + day).to_s.gsub("-","") }.join(",")
  end

  def invalid_limit?(limit:)
    limit == 0
  end

  def too_popular_or_unpopular?(accepted:, limit:)
    accepted_per_limit = accepted / limit.to_f
    accepted_per_limit <= 0.7 || accepted_per_limit >= 1
  end
end
