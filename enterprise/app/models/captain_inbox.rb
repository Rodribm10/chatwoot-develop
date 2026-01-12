# frozen_string_literal: true

# == Schema Information
#
# Table name: captain_inboxes
#
#  id                     :bigint           not null, primary key
#  captain_assistant_id   :bigint           not null
#  inbox_id               :bigint           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class CaptainInbox < ApplicationRecord
  self.table_name = 'captain_inboxes'

  belongs_to :inbox
  belongs_to :assistant, class_name: 'Captain::Assistant', foreign_key: 'captain_assistant_id'
  belongs_to :unit, class_name: 'Captain::Unit', foreign_key: 'captain_unit_id', optional: true
end
