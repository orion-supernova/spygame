#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the SpygameLiveActivity widget extension target to Runner.xcodeproj
# in an idempotent way. Safe to re-run.
#
# Usage:  ruby ios/scripts/setup_live_activity.rb
#
# Requirements: the `xcodeproj` gem. CocoaPods (which Flutter requires for
# iOS builds) bundles it; if `require 'xcodeproj'` fails on the system Ruby,
# the script falls back to the gem path that Homebrew CocoaPods uses.

begin
  require 'xcodeproj'
rescue LoadError
  cocoapods_gem_home = `brew --prefix cocoapods 2>/dev/null`.strip
  if !cocoapods_gem_home.empty? && File.directory?("#{cocoapods_gem_home}/libexec")
    ENV['GEM_HOME'] = "#{cocoapods_gem_home}/libexec"
    Gem.clear_paths
    require 'xcodeproj'
  else
    abort "xcodeproj gem missing. Run: gem install xcodeproj"
  end
end

PROJECT_PATH = File.expand_path('..', __dir__) + '/Runner.xcodeproj'
EXTENSION_NAME = 'SpygameLiveActivity'
EXTENSION_DIR = File.expand_path('..', __dir__) + "/#{EXTENSION_NAME}"
EXTENSION_BUNDLE_SUFFIX = 'LiveActivity'
SHARED_ATTRIBUTES_FILE = 'Runner/RoundActivityAttributes.swift'
RUNNER_CHANNEL_FILE = 'Runner/LiveActivityChannel.swift'
EXTENSION_INFO_PLIST = "#{EXTENSION_NAME}/Info.plist"
EXTENSION_DEPLOYMENT_TARGET = '16.2'

# Read marketing/build version from pubspec.yaml — the extension target
# can't inherit FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER env vars (those
# are only set for the Runner target by xcode_backend.sh), and iOS
# requires the appex CFBundleShortVersionString to match the host app
# exactly or installation fails with "Invalid placeholder attributes".
pubspec_path = File.expand_path('../../pubspec.yaml', __dir__)
pubspec_version = File.foreach(pubspec_path)
                     .find { |l| l =~ /^\s*version:\s*\S/ }
                     &.match(/version:\s*([^\s#]+)/)
                     &.captures&.first
abort "Could not read version from pubspec.yaml" unless pubspec_version
marketing_version, project_version = pubspec_version.split('+', 2)
project_version ||= '1'

abort "Project not found at #{PROJECT_PATH}" unless File.directory?(PROJECT_PATH)

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target missing'

# 1. Make sure the shared attributes file is in the Runner target.
runner_group = project.main_group['Runner'] or abort 'Runner group missing'

def ensure_file_ref(group, project_relative_path, source_tree: '<group>')
  existing = group.files.find { |f| f.path == File.basename(project_relative_path) }
  return existing if existing
  group.new_reference(File.basename(project_relative_path)).tap do |ref|
    ref.source_tree = source_tree
  end
end

attributes_ref = ensure_file_ref(runner_group, 'RoundActivityAttributes.swift')
unless runner.source_build_phase.files_references.include?(attributes_ref)
  runner.source_build_phase.add_file_reference(attributes_ref, true)
end

channel_ref = ensure_file_ref(runner_group, 'LiveActivityChannel.swift')
unless runner.source_build_phase.files_references.include?(channel_ref)
  runner.source_build_phase.add_file_reference(channel_ref, true)
end

# 2. Create or fetch the extension group.
ext_group = project.main_group[EXTENSION_NAME] || project.main_group.new_group(EXTENSION_NAME, EXTENSION_NAME)

bundle_ref = ensure_file_ref(ext_group, 'SpygameLiveActivityBundle.swift')
widget_ref = ensure_file_ref(ext_group, 'RoundActivityWidget.swift')
info_ref   = ensure_file_ref(ext_group, 'Info.plist')

# Reference the shared attributes file from the extension group too, but
# without re-adding the file (it's the same on disk under Runner/).
shared_ref_in_ext = ext_group.files.find { |f| f.path == 'RoundActivityAttributes.swift' }
unless shared_ref_in_ext
  shared_ref_in_ext = ext_group.new_reference('../Runner/RoundActivityAttributes.swift')
  shared_ref_in_ext.source_tree = '<group>'
end

# 3. Create the extension target if it doesn't exist.
ext_target = project.targets.find { |t| t.name == EXTENSION_NAME }
unless ext_target
  ext_target = project.new_target(
    :app_extension,
    EXTENSION_NAME,
    :ios,
    EXTENSION_DEPLOYMENT_TARGET
  )
end

# Configure the extension target's build settings.
runner_bundle_id = runner.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] || 'com.walhallaa.spygame.v02202404'
ext_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{runner_bundle_id}.#{EXTENSION_BUNDLE_SUFFIX}"
  s['INFOPLIST_FILE'] = EXTENSION_INFO_PLIST
  s['IPHONEOS_DEPLOYMENT_TARGET'] = EXTENSION_DEPLOYMENT_TARGET
  s['SWIFT_VERSION'] = '5.0'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['SKIP_INSTALL'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['INFOPLIST_KEY_CFBundleDisplayName'] = 'Spygame Live Activity'
  s['INFOPLIST_KEY_NSHumanReadableCopyright'] = ''
  s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = ''
  s['CURRENT_PROJECT_VERSION'] = project_version
  s['MARKETING_VERSION'] = marketing_version
end

# Match Runner team if available so signing is consistent.
runner_team = runner.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
if runner_team && !runner_team.empty?
  ext_target.build_configurations.each do |c|
    c.build_settings['DEVELOPMENT_TEAM'] = runner_team
  end
end

# 4. Wire the source files into the extension's compile phase.
ext_sources = ext_target.source_build_phase
[bundle_ref, widget_ref, shared_ref_in_ext].each do |ref|
  next if ext_sources.files_references.include?(ref)
  ext_sources.add_file_reference(ref, true)
end

# 5. Embed the extension into the Runner app bundle.
embed_phase = runner.copy_files_build_phases.find { |ph| ph.name == 'Embed Foundation Extensions' }
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

# Position the Embed Foundation Extensions phase BEFORE Flutter's
# "Thin Binary" script and the CocoaPods script phases. Putting it at
# the very end of the build phases creates a dependency cycle in
# `xcbuild` because Thin Binary then implicitly depends on Runner.app's
# contents while the embed copy is still pending.
runner.build_phases.delete(embed_phase)
thin_binary_idx = runner.build_phases.find_index { |ph| ph.respond_to?(:name) && ph.name == 'Thin Binary' }
insert_idx = thin_binary_idx || runner.build_phases.length
runner.build_phases.insert(insert_idx, embed_phase)

ext_product_ref = ext_target.product_reference
unless embed_phase.files_references.include?(ext_product_ref)
  build_file = embed_phase.add_file_reference(ext_product_ref, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# NOTE: Do NOT call `runner.add_dependency(ext_target)` here. The Embed
# Foundation Extensions copy phase already creates an implicit build-order
# dependency, and adding an explicit one on top causes the modern
# `xcbuild` to detect a cycle (it traces Runner → ext appex → embed copy
# → Runner.app → Runner).

project.save

puts "[OK] SpygameLiveActivity target wired up."
puts "    Bundle id: #{runner_bundle_id}.#{EXTENSION_BUNDLE_SUFFIX}"
puts "    Deployment: iOS #{EXTENSION_DEPLOYMENT_TARGET}"
