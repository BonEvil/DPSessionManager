Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "DPSessionManager"
  s.version      = "3.0.0"
  s.summary      = "Base framework for service calls."

  s.description  = <<-DESC
The base framework for creating more complex service calls to a server-base API.
                   DESC

  s.homepage     = "http://www.danielperson.com"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = { :type => "MIT", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "Daniel Person" => "daniel.person@yahoo.com" }
  s.social_media_url   = "http://twitter.com/DanielDPerson"


  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios, "8.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => "git@bitbucket.org:66BonEvil/dpsessionmanager.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "DPSessionManager", "DPSessionManager/**/*.{swift}"
  s.public_header_files = "DPSessionManager/**/*.h"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.dependency Bolts-Swift', '1.2.0'

end
