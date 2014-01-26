# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'airplane'
  app.frameworks += ['SpriteKit', 'AVFoundation', 'CoreMotion']
  app.device_family = :ipad
  app.interface_orientations = [:portrait]

  app.codesign_certificate = ENV['RUBYMOTION_CERTIFICATE']
  app.provisioning_profile = ENV['RUBYMOTION_PROFILE']
end
