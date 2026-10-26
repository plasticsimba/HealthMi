#!/bin/bash
set -euo pipefail

workflow=".github/workflows/ios-ci.yml"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_fixed() {
  local needle="$1"
  local label="$2"
  grep -Fq -- "$needle" "$workflow" || fail "$label"
}

[[ -f "$workflow" ]] || fail "workflow missing: $workflow"

require_fixed "permissions:" "top-level permissions are missing"
require_fixed "contents: read" "workflow must use read-only repository contents permission"
require_fixed "runs-on: macos-26" "workflow must use the standard Apple Silicon macos-26 runner"
require_fixed "brew install xcodegen" "workflow must install XcodeGen explicitly"
require_fixed "xcodegen generate" "workflow must generate the Xcode project"
require_fixed "xcodebuild test" "workflow must run the simulator test target"
require_fixed "platform=iOS Simulator" "workflow must target an iOS Simulator"
require_fixed "-sdk iphoneos" "workflow must build for a physical iOS device SDK"
require_fixed "CODE_SIGNING_ALLOWED=NO" "device build must disable code signing"
require_fixed "CODE_SIGNING_REQUIRED=NO" "device build must not require code signing"
require_fixed 'test ! -e "$app_path/embedded.mobileprovision"' "workflow must reject an embedded provisioning profile"
require_fixed "Payload/HealthMi.app" "workflow must package the unsigned app in a Payload directory"
require_fixed "actions/upload-artifact@" "workflow must upload the unsigned artifact"

if grep -Eq 'macos-[^[:space:]]*(large|xlarge)' "$workflow"; then
  fail "paid larger runner label is forbidden"
fi

if grep -Eiq '(secrets\.|\.p12|certificate|provisioning[ _-]?profile|passToken|serviceToken)' "$workflow"; then
  fail "workflow contains a credential, certificate, profile, or Xiaomi token reference"
fi

[[ "$(grep -Ec '\.mobileprovision' "$workflow")" -eq 1 ]] || \
  fail "provisioning-profile path may appear only in the explicit absence check"

printf 'PASS: iOS CI workflow policy checks\n'
