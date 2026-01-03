---
description: Release a new gem version with changelog
allowed-tools: Read, Edit, Write, Bash, Glob
---

Release workflow for the zenrows gem. Follow these steps in order:

1. **Pre-flight checks**
   - Run `bundle exec rake test` - ensure all tests pass
   - Run `bundle exec rubocop` - ensure no offenses
   - Run `make rbs` - validate RBS types

2. **Changelog & README** (REQUIRED)
   - Read CHANGELOG.md - add entry with today's date and version
   - Read README.md - update if new features need documentation
   - Use format: `## [X.Y.Z] - YYYY-MM-DD` with `### Added/Changed/Fixed` sections

3. **Version bump**
   - Read current version from lib/zenrows/version.rb
   - Bump version (patch/minor/major based on changes)
   - Update lib/zenrows/version.rb
   - Run `bundle install` to update Gemfile.lock

4. **Commit and tag**
   - Commit changelog: `docs: add changelog entry for vX.Y.Z`
   - Commit version bump: `chore: bump version to X.Y.Z`
   - Push to origin
   - Create and push tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`

5. **Publish**
   - Run `bundle exec rake build`
   - Inform user to run `gem push pkg/zenrows-X.Y.Z.gem` with OTP

6. **GitHub Release**
   - Create GitHub release: `gh release create vX.Y.Z --title "vX.Y.Z" --notes-from-tag`
   - Or generate notes from changelog section for this version

Ask user for version bump type (patch/minor/major) before starting.
