require 'json'
gem 'xcodeproj', '1.28.1'
require 'xcodeproj'

project = Xcodeproj::Project.open(ARGV.fetch(0))
signing = JSON.parse(File.read(ARGV.fetch(1)))
signing.fetch('profiles').each do |name, uuid|
  target = project.targets.find { |item| item.name == name }
  abort "Missing Xcode target: #{name}" unless target
  target.build_configurations.each do |config|
    settings = config.build_settings
    settings.keys.grep(/^(CODE_SIGN_IDENTITY|PROVISIONING_PROFILE|DEVELOPMENT_TEAM)/).each do |key|
      settings.delete(key)
    end
    settings['CODE_SIGN_STYLE'] = 'Manual'
    settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    settings['DEVELOPMENT_TEAM'] = signing.fetch('team')
    settings['PROVISIONING_PROFILE_SPECIFIER'] = uuid
  end
end
project.save
