Pod::Spec.new do |s|
  s.name             = 'lqPerf'
  s.version          = '0.1.0'
  s.summary          = 'Lightweight iOS performance monitoring SDK.'
  s.description      = <<-DESC
A lightweight iOS performance monitoring SDK with FPS/CPU/Memory/Lag/Network metrics, device info, crash linkage, and exporters.
  DESC
  s.homepage         = 'https://github.com/feather2222/lqPerf'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'feather2222' => '1402479908@qq.com' }
  s.source           = { :git => 'https://github.com/feather2222/lqPerf.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source_files = 'lqPerf/**/*.{swift}'

  s.frameworks = 'Foundation', 'UIKit'
  s.weak_frameworks = 'BackgroundTasks'
end
