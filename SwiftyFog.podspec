#
# Be sure to run `pod lib lint SwiftyFog.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyFog'
  s.version          = '0.1.0'
  s.summary          = 'Swift implementations of various FogLight entities for over the wire communications. Includes an MQTT client'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This library implements Swift structures to work with a FogLight client. A full performant MQTT client is built in.
                       DESC

  s.homepage         = 'https://github.com/oci-pronghorn/SwiftyFog'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'BSD-3', :file => 'LICENSE' }
  s.author           = { 'dsjove' => 'giovanninid@ociweb.com' }
  s.source           = { :git => 'https://github.com/oci-pronghorn/SwiftyFog.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'SwiftyFog/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SwiftyFog' => ['SwiftyFog/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
