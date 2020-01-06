# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include CurrentUser
  include TelegramHelpers
  include HandleErrors
  include LaterMessage

  def message(message)
    stored_message = store_message message
    respond_with :message, text: t('.response', stored_message: stored_message)
  end

  def set_next_maintenance!(mileage)
    current_car.update! next_maintenance_mileage: mileage
    later_message t('.questions_finished')
    respond_with :message, text: t('.success'), parse_mode: :Markdown
  end

  def info!(*)
    if current_car.present?
      respond_with :message, text: t('.success'), parse_mode: :Markdown
    else
      respond_with :message, text: t('.empty'), parse_mode: :Markdown
    end
  end

  def set_mileage!(mileage)
    mileage = mileage.to_f
    current_user.messages.create!(
      value: mileage,
      kind: :mileage,
      telegram_message_id: telegram_message_id,
      telegram_date: telegram_date
    )
    current_car.update! current_mileage: mileage
    save_context :set_next_maintenance!
    later_message t('.next_maintenance_question')
    respond_with :message, text: t('.success', car: current_car), parse_mode: :Markdown
  end

  def set_insurance_date!(date)
    current_car.update! insurance_end_date: date == '0' ? nil : Date.parse(date)
    save_context :set_mileage!
    later_message t('.mileage_question')
    respond_with :message, text: t('.success', car: current_car), parse_mode: :Markdown
  end

  def set_number!(number = nil)
    current_car.update! number: number == '0' ? nil : number
    save_context :set_insurance_date!
    later_message t('.insurance_question')
    respond_with :message, text: t('.success', car: current_car), parse_mode: :Markdown
  end

  def set_car!(model = nil, mark = nil, year = nil)
    if model.present? && mark.present? && year.present?
      if current_car.present?
        current_car.update model: model, mark: mark, year: year
      else
        current_user.create_car! model: model, mark: mark, year: year
      end

      save_context :set_number!
      later_message t('.number_question')
      respond_with :message, text: t('.success', car: current_car), parse_mode: :Markdown
    else
      save_context :set_car!
      respond_with :message, text: t('.wrong'), parse_mode: :Markdown
    end
  end

  def start!(*)
    # TODO: if current_car.present?
    save_context :set_car!
    later_message t('.car_question'), 5.seconds
    respond_with :message, text: t('.response', user: current_user), parse_mode: :Markdown
  end

  private

  def store_message(message)
    attrs = {
      telegram_message_id: telegram_message_id,
      telegram_date: telegram_date
    }

    message_text = message['text']

    # Сохраняем только текстовые сообщения не нужно нам базу забивать картинками всякими,
    # пусть лежат в истории чата
    #
    return if message_text.blank?

    splitted_message = message_text.split
    value = splitted_message.first.presence
    extra_text = splitted_message.drop(1).join ' '

    if value_numeric? value
      if extra_text.present?
        attrs.merge! value: value, text: extra_text, kind: :spending
      else
        attrs.merge! value: value, kind: :mileage
      end
    else
      attrs.merge! text: message_text
    end

    current_user.messages.create! attrs
  end

  # rubocop:disable Style/MultipleComparison
  def value_numeric?(value)
    value.present? && (value.to_f.to_s == value || value.to_i.to_s == value)
  end
  # rubocop:enable Style/MultipleComparison
end
