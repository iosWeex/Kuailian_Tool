Pod::Spec.new do |s|
  s.name         = "Kuailian_Tool"
  s.version      = "0.0.1" # 版本号，后面打tag要和这个一致
  s.summary      = "快链tool"
  s.homepage     = "https://github.com/iosWeex/Kuailian_Tool"
  s.license      = "MIT"
  s.author       = { "xxx" => "xxx@xxx.com" }
  # 👉 这里填你的git仓库地址
  s.source       = { :git => "https://github.com/iosWeex/Kuailian_Tool.git", :tag => s.version }
  
  s.source_files = "Sources/**/*.swift"
  s.platform     = :ios, "13.0"
  s.swift_version = "5.0"
  s.dependency 'Alamofire','~> 5.9'
  s.dependency 'SVProgressHUD'
  s.dependency 'SAMKeychain'
  s.frameworks = "StoreKit"
end
