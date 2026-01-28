# frozen_string_literal: true

class AccountEvent < ApplicationRecord
  belongs_to :account
  belongs_to :resource
end
