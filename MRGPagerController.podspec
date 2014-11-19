Pod::Spec.new do |s|
  s.name             = "MRGPagerController"
  s.version          = "0.1.3"
  s.summary          = "An highly customizable pager controller."
  s.homepage         = "https://github.com/Mirego/MRGPagerController"
  s.license          = 'BSD 3-Clause'
  s.authors          = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source           = { :git => "https://github.com/Mirego/MRGPagerController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Mirego'

  s.platform         = :ios, '7.0'
  s.requires_arc     = true

  s.source_files     = 'Pod/Classes'
end
