# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

require 'rails_helper'

RSpec.describe TelegramWebhooksController, telegram_bot: :rails do
  # Main method is #dispatch(update). Some helpers are:
  # dispatch_message(text, options = {})
  # dispatch_command(cmd, *args)

  describe '#start!' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message(/Привет/) }
  end

  describe '#set_car!' do
    context 'wrong value' do
      subject { -> { dispatch_command :set_car } }
      it { should respond_with_message(/Напишите/) }
    end
    context 'value exists' do
      subject { -> { dispatch_command :set_car, 'nissan x-trail 2010' } }
      it { should respond_with_message(/Отлично/) }
    end
  end

  describe '#set_number!' do
    subject { -> { dispatch_command :set_number, 'AB123C21' } }
    it { should respond_with_message(/Регистрационный номер/) }
  end

  describe '#set_mileage!' do
    subject { -> { dispatch_command :set_mileage, '1231231' } }
    it { should respond_with_message(/текущий пробег/) }
  end

  describe '#set_insurance_date!' do
    subject { -> { dispatch_command :set_insurance_date, '31-12-2012' } }
    it { should respond_with_message(/Понятно/) }
  end

  describe '#set_next_maintenance!' do
    subject { -> { dispatch_command :set_next_maintenance, '132121' } }
    it { should respond_with_message(/следующее ТО/) }
  end
end
