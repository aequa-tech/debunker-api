# frozen_string_literal: true

set :chronic_options, hours24: true

every :day, at: '00:10' do
  runner 'TokenReloader.reload_active_keys'
end
