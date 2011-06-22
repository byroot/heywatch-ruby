Gem::Specification.new do |s|
  s.name        = 'heywatch'
  s.version     = '1.0.3'
  s.summary     = "Client library and CLI to encode videos with HeyWatch"
  s.description = "Client Library for encoding Videos with HeyWatch, a Video Encoding Web Service."
  s.authors     = ["Bruno Celeste"]
  s.email       = 'bruno@particle-s.com'
  s.files       = ["lib/heywatch.rb", "bin/heywatch"]
  s.homepage    = 'http://heywatch.com'
  s.bindir      = 'bin'
  s.executables = 'heywatch'
  
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'json'
end