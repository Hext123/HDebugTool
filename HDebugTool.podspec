#
# Be sure to run `pod lib lint HDebugTool.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HDebugTool'
  s.version          = '1.1.0'
  s.summary          = '一个用于iOS项目的调试工具, 可以用于切换环境, 清除缓存等等, 帮助测试项目'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  一个用于iOS项目的调试工具, 可以用于切换环境, 清除缓存等等, 帮助测试项目. 1.1.0 版本开始支持添加自定义设置项
                       DESC
                       
  s.homepage         = 'https://github.com/Hext123/HDebugTool'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hext' => 'hext123@foxmail.com' }
  s.source           = { :git => 'https://github.com/Hext123/HDebugTool.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'

  s.source_files = 'HDebugTool/Classes/**/*.*'
  s.resources = 'HDebugTool/Assets/**/*.*'
  
  # s.resource_bundles = {
  #   'HDebugTool' => ['HDebugTool/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
end
