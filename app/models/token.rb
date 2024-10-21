# frozen_string_literal: true

class Token < ApplicationRecord
  include Utils

  belongs_to :api_key

  enum perform_status: %i[initial in_progress incomplete_evaluation success partial failure invalid], _prefix: true
  enum callback_status: %i[initial success partial failure invalid], _prefix: true

  validates :value, presence: true, uniqueness: true
  scope :available, -> { where(used_on: nil) }

  def available?
    used_on.nil?
  end

  def occupy!(parsed_payload)
    update_columns(used_on: parsed_payload.url, perform_status: :in_progress, callback_status: :initial,
                   payload_json: parsed_payload.raw, response_json: response_object.to_json,
                   perform_retries: 0, callback_retries: 0, request_started_at: Time.zone.now)
    Notification.request(token: self, type: :started)
  end

  def status!(status, kind:)
    return unless kind.in?(%i[perform callback])

    update_columns("#{kind}_status": status)
    Notification.request(token: self, type: :updated)
  end

  def increase_retries!(kind:)
    return unless kind.in?(%i[perform callback])

    update_columns("#{kind}_retries": send("#{kind}_retries") + 1)
    Notification.request(token: self, type: :updated)
  end

  def persist!(content, kind:)
    return unless kind.in?(%i[payload response])

    content = content.to_json if content.is_a?(Hash)
    update_columns("#{kind}_json": content)
    Notification.request(token: self, type: :updated)
  end

  def finish!
    update_columns(request_ended_at: Time.zone.now, perform_status: scrape_outcome,
                   callback_status: callback_outcome)
    Notification.request(token: self, type: :finished)
    destroy!

    TokenReloader.new(api_key).regenerate_single_token if negative_processes?
  end

  def negative_processes?
    %i[failure invalid].include?(scrape_outcome) ||
      %i[failure invalid].include?(callback_outcome)
  end

  def response_object
    return JSON.parse(response_json).deep_symbolize_keys if response_json.present?

    obj = {}
    obj[:scrape] = { request_id: nil }
    obj[:evaluation] = { analysis_id: nil, data: {}, analysis_status: 0, callback_status: 0 }
    obj[:explanations] = { data: [], analysis_status: 0, callback_status: 0 }
    obj
  end

  def scrape_outcome
    payload = payload_object
    response = response_object

    return :invalid if payload[:analysisTypes].blank?
    return :failure unless response[:scrape][:request_id].present?
    return :incomplete_evaluation if response[:evaluation][:analysis_status] == incomplete_status

    results = payload[:analysisTypes].keys.map do |analysis_type|
      success_status?(response[analysis_type] ? response[analysis_type][:analysis_status] : 400)
    end

    if results.all?
      :success
    else
      results.any? ? :partial : :failure
    end
  end

  def callback_outcome
    payload = payload_object
    response = response_object

    return :invalid if payload[:analysisTypes].blank?

    results = payload[:analysisTypes].keys.map do |analysis_type|
      success_status?(response[analysis_type] ? response[analysis_type][:callback_status] : 400)
    end

    if results.all?
      :success
    else
      results.any? ? :partial : :failure
    end
  end

  private

  def payload_object
    JSON.parse(payload_json.presence || { analysis_types: {} }.to_json).deep_symbolize_keys
  end
end
