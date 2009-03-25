version ||= Rails.version.split('.')

if version[0].to_i == 2 && version[1].to_i < 3 #version prior to 2.3 use the legacy store
  require 'legacy_smart_session_store'
  Object.const_set(:SmartSessionStore, LegacySmartSessionStore)
else
  require 'smart_session_store'
end