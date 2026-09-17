require 'xcodeproj'
p = Xcodeproj::Project.open('Veltranomixa.xcodeproj')
unless p.targets.any? { |t| t.name == 'LuckyIslandUITests' }
  app = p.targets.find { |t| t.name == 'Veltranomixa' }
  target = p.new_target(:ui_test_bundle, 'LuckyIslandUITests', :ios, '16.0')
  target.add_dependency(app)
  group = p.main_group.new_group('UITests', 'UITests')
  target.add_file_references([group.new_file('LuckyIslandUITests.swift')])
  target.build_configurations.each do |c|
    c.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ccvl.Veltranomixa.UITests'
    c.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    c.build_settings['SWIFT_VERSION'] = '5.0'
    c.build_settings['TEST_TARGET_NAME'] = 'Veltranomixa'
    c.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  end
  p.save
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(app)
  scheme.add_test_target(target)
  scheme.set_launch_target(app)
  scheme.save_as(p.path, 'Veltranomixa', true)
end
