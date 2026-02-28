#!/usr/bin/env ruby
# Run tests on an available iOS simulator.
# Picks the first Booted device, or the first available iPhone if none are booted.

scheme = ARGV[0] || "AtomicArch"
project = ARGV[1] || "AtomicArch.xcodeproj"
extra_args = ARGV[2..] || []

uuid_regex = /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/

destination = nil
devices_output = `xcrun simctl list devices available 2>/dev/null`

# Prefer booted iPhone
devices_output.each_line do |line|
  next unless line =~ /iPhone/i && line.include?("Booted")
  if (match = line.match(uuid_regex))
    destination = "id=#{match[0]}"
    puts "Using booted simulator: #{match[0]}"
    break
  end
end

# Fallback to first available iPhone
if destination.nil?
  devices_output.each_line do |line|
    next unless line =~ /iPhone/i
    if (match = line.match(uuid_regex))
      destination = "id=#{match[0]}"
      puts "Using first available iPhone: #{match[0]}"
      break
    end
  end
end

# Fallback to generic destination
if destination.nil?
  destination = "platform=iOS Simulator,name=iPhone 16 Pro,OS=latest"
  puts "No specific simulator found, using: #{destination}"
end

puts "Running tests with destination: #{destination}"

cmd = [
  "xcodebuild", "test",
  "-project", project,
  "-scheme", scheme,
  "-destination", destination,
  "-enableCodeCoverage", "YES"
] + extra_args

exec(*cmd)
