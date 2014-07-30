
Pod::Spec.new do |s|

  s.name         = "ECStretchableHeaderView"
  s.version      = "1.0.0"
  s.summary      = "A header view that attaches on top of a UIScrollView and reacts to scrolling gestures to expand or contract itself."
  s.homepage     = "https://github.com/ericcastro/ECStretchableHeaderView"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "Eric Castro" => "eric@cast.ro" }
  s.social_media_url   = "http://twitter.com/_eric_castro"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/ericcastro/ECStretchableHeaderView", :tag => "#{s.version}" }
  s.source_files  = "ECStretchableHeaderView.{h,m}"

end
