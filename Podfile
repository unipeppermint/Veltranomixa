source 'https://cdn.cocoapods.org/'
platform :ios, '16.0'
use_frameworks! :linkage => :static
target 'Veltranomixa' do
  pod 'SnapKit', '5.7.1'
end

# CocoaPods 1.17 writes this temporary file; declare it for Xcode's script sandbox.
post_integrate do |installer|
  installer.aggregate_targets.map(&:user_project).uniq.each do |project|
    project.native_targets.each do |target|
      target.shell_script_build_phases.each do |phase|
        next unless phase.name == '[CP] Copy Pods Resources'
        path = '$(PODS_ROOT)/resources-to-copy-$(TARGETNAME).txt'
        phase.output_paths = ((phase.output_paths || []) + [path]).uniq
      end
    end
    project.save
  end
end
