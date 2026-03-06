# Homebrew cask for Crest
#
# Host this file in the shared tap repo: github.com/USERNAME/homebrew-tap
#   Casks/crest.rb
#
# Install:
#   brew install --cask USERNAME/tap/crest
#
# To update after a new release:
#   1. Replace `version` with the new version string.
#   2. Replace `sha256` with the SHA256 printed in the GitHub Actions release summary.

cask "crest" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_ACTIONS_SUMMARY"

  url "https://github.com/REPLACE_WITH_YOUR_USERNAME/Crest/releases/download/v#{version}/Crest-#{version}.dmg"

  name "Crest"
  desc "macOS menu bar stock and crypto price tracker"
  homepage "https://zvh.io"

  app "Crest.app"

  caveats <<~EOS
    Crest is not notarized. On first launch, right-click the app and select "Open",
    then confirm in the dialog that appears.

    Alternatively, remove the quarantine attribute:
      sudo xattr -d com.apple.quarantine /Applications/Crest.app
  EOS
end
