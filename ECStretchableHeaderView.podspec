
Pod::Spec.new do |s|

  s.name         = "ECStretchableHeaderView"
  s.version      = "1.0.0"
  s.summary      = "A header view that attaches on top of a UIScrollView and reacts to scrolling gestures to expand or contract itself."

  s.description  = <<-DESC
                   * A multi purpose header view that you can attach to a UITableView (or any UIScrollView for that matter), allowing you to maximize the content view by expanding and contracting the top header upon scrolling down or up, or by delegating the decision on when to do this through a another object.
                   * 
                   * Useful when the full header isn't needed yet it is still required (but might have some buttons or any other interactive controls that need to remain visible)
                   * 
                   DESC

  s.homepage     = "https://github.com/ericcastro/ECStretchableHeaderView"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "Eric Castro" => "eric@cast.ro" }
  s.social_media_url   = "http://twitter.com/_eric_castro"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/ericcastro/ECStretchableHeaderView", :tag => "1.0.0" }
  s.source_files  = "ECStretchableHeaderView.{h,m}"

end
