Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.name = 'FitpaySDK'
  s.version = '0.1.0'
  s.license = 'MIT'
  s.summary = 'Swift based library for the Fitpay Platform'
  s.homepage = 'https://github.com/fitpay/fitpay-ios-sdk'
  s.authors = { 'Ben Walford' => 'ben@fit-pay.com' }
  s.source = { :git => 'https://github.com/fitpay/fitpay-ios-sdk.git', :branch => 'external_fpcrypto' }
  s.source_files = 'FitpaySDK/**/*.{swift,m,h}'
  s.private_header_files = 'FitpaySDK/**/SECP256R1KeyPairContainer+Private.h'
  s.dependency 'Alamofire', '~> 3.0'
  s.dependency 'ObjectMapper', '~> 1.2.0'
  s.dependency 'AlamofireObjectMapper', '~> 3.0.0'
  s.dependency 'JWTDecode', '~> 1.0.0'
  s.dependency 'libPusher', '~> 1.6.1'
  s.dependency 'KeychainAccess', '~> 2.3.4'
  s.dependency 'OpenSSL-Universal', '~> 1.0'
end
