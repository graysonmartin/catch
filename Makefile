SIMULATOR_ID = 427BD9BF-F3B2-4985-B434-3B872EC26E28
PROJECT = catch.xcodeproj
APP_SCHEME = catch
TEST_SCHEME = catchTests
BUNDLE_ID = com.graysonmartin.catch
APP_PATH = $(shell find ~/Library/Developer/Xcode/DerivedData/catch-*/Build/Products/Debug-iphonesimulator/catch.app -maxdepth 0 2>/dev/null | head -1)

.PHONY: test test-fast test-all test-verbose test-serial boot-sim kill-sim clean-build build run install reset-sim \
	db-push db-push-prod db-status db-new db-link

# --- Simulator ---

boot-sim:
	@xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	@sleep 1

kill-sim:
	xcrun simctl shutdown $(SIMULATOR_ID)

reset-sim:
	xcrun simctl shutdown $(SIMULATOR_ID) 2>/dev/null || true
	xcrun simctl erase $(SIMULATOR_ID)
	@echo "Simulator wiped clean. Next run will be a fresh install."

# --- Build & Run ---

build: boot-sim
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(APP_SCHEME) \
		-destination 'id=$(SIMULATOR_ID)' \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -5

run: build
	@xcrun simctl terminate $(SIMULATOR_ID) $(BUNDLE_ID) 2>/dev/null || true
	xcrun simctl install $(SIMULATOR_ID) "$(APP_PATH)"
	xcrun simctl launch $(SIMULATOR_ID) $(BUNDLE_ID)
	@echo "App launched."

install:
	@xcrun simctl terminate $(SIMULATOR_ID) $(BUNDLE_ID) 2>/dev/null || true
	xcrun simctl install $(SIMULATOR_ID) "$(APP_PATH)"
	xcrun simctl launch $(SIMULATOR_ID) $(BUNDLE_ID)
	@echo "Reinstalled from last build."

# --- Tests ---

# Package tests only — no simulator, runs in seconds
test-fast:
	swift test --package-path .

# Package + Xcode tests
test-all: test-fast test

test: boot-sim
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(TEST_SCHEME) \
		-destination 'id=$(SIMULATOR_ID)' \
		-enableCodeCoverage NO \
		-skipPackagePluginValidation \
		-parallel-testing-enabled YES \
		CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -30

test-verbose: boot-sim
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(TEST_SCHEME) \
		-destination 'id=$(SIMULATOR_ID)' \
		-enableCodeCoverage NO \
		-skipPackagePluginValidation \
		-parallel-testing-enabled YES \
		-showBuildTimingSummary \
		CODE_SIGNING_ALLOWED=NO

test-serial: boot-sim
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(TEST_SCHEME) \
		-destination 'id=$(SIMULATOR_ID)' \
		-enableCodeCoverage NO \
		CODE_SIGNING_ALLOWED=NO

# --- Database Migrations ---

SUPABASE = npx supabase

db-push:
	$(SUPABASE) db push
	@echo "Migrations applied to linked project (dev)."

db-push-prod:
	@echo "WARNING: Pushing migrations to PRODUCTION."
	@echo "Make sure you have linked to the prod project: make db-link ref=<prod-ref>"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(SUPABASE) db push
	@echo "Migrations applied to PROD."

db-status:
	$(SUPABASE) migration list --linked

db-new:
	@test -n "$(name)" || (echo "Usage: make db-new name=create_foo_table" && exit 1)
	$(SUPABASE) migration new $(name)
	@echo "Created new migration. Edit the file in supabase/migrations/."

db-link:
	@test -n "$(ref)" || (echo "Usage: make db-link ref=your-project-ref" && exit 1)
	$(SUPABASE) link --project-ref $(ref)
	@echo "Linked to project $(ref)."

# --- Cleanup ---

clean-build:
	rm -rf ~/Library/Developer/Xcode/DerivedData/catch-*
