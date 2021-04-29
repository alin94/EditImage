#
#  Be sure to run `pod spec lint HLEditImage.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "HLEditImage"
  s.version      = "0.2.2"
  s.summary      = "图片编辑工具"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                    图片编辑工具 涂鸦（箭头、椭圆、矩形）、裁剪、旋转、添加水印
                   DESC

  s.homepage     = "https://github.com/alin94/HLEditImage.git"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  # s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "alin" => "zhaohl@dogesoft.cn" }
  # Or just: s.author    = "alin"
  # s.authors            = { "alin" => "zhaohl@dogesoft.cn" }
  # s.social_media_url   = "http://twitter.com/alin"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  s.platform     = :ios, "9.0"

  #  When using multiple platforms
  s.ios.deployment_target = "9.0"

  # s.pod_target_xcconfig = { 'VALID_ARCHS' => 'arm64' }


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #
  s.source       = { :git => "https://github.com/alin94/HLEditImage.git", :tag => s.version.to_s}

  # s.source       = { :git => "https://github.com/alin94/HLEditImage.git", :tag => s.version.to_s, :commit => "bc35a382140dded5526ff7a13538d76498333217"}


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #
  # s.source_files = "HLEditImage/Classes/*.h" ,"HLEditImage/Classes/**/*.{h,m}"

    s.source_files = "HLEditImage/Classes/SLUtilsMacro.h"

    s.subspec 'Tool' do  |sst|
      sst.source_files = "HLEditImage/Classes/Tool/*.{h,m}"
    end

    s.subspec 'Category' do  |ssc|
      ssc.source_files = "HLEditImage/Classes/Category/*.{h,m}"
    end
    s.subspec 'AnimateImageView' do  |ssa|
      ssa.vendored_frameworks = 'Vendor/WebP.framework'
      ssa.source_files = "HLEditImage/Classes/AnimateImageView/*.{h,m}"
    end

    s.subspec 'View' do  |ssv|
      ssv.dependency  'HLEditImage/AnimateImageView'
      ssv.dependency 'HLEditImage/Category'
      ssv.dependency 'HLEditImage/Tool'

      ssv.source_files = "HLEditImage/Classes/View/*.{h,m}" , "HLEditImage/Classes/SLUtilsMacro.h"
    end

    s.subspec 'Controller' do  |ssvc|
      ssvc.dependency  'HLEditImage/AnimateImageView'
      ssvc.dependency 'HLEditImage/Category'
      ssvc.dependency 'HLEditImage/Tool'
      ssvc.dependency 'HLEditImage/View'
      ssvc.source_files = "HLEditImage/Classes/Controller/*.{h,m}" , "HLEditImage/Classes/SLUtilsMacro.h"
    end

  # s.source_files  =  "HLEditImage/Classes/**/*.{h,m}" , "HLEditImage/Classes/*.h"
  # s.public_header_files = "HLEditImage/Classes/SLEditImage.h"
  # s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"
  # s.resources = "HLEditImage/Assets/*.png"
#资源文件地址
  s.resource_bundles = {
      'HLEditImage' => ['HLEditImage/Assets/*']
   } 


  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
  


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #
  s.frameworks = 'Foundation', 'UIKit'
  # s.vendored_frameworks = 'HLEditImage/Classes/AnimateImageView/WebP.framework'
  # s.ios.vendored_frameworks = 'Vendor/WebP.framework'
  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"


end
