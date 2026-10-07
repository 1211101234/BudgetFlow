#!/bin/zsh

set -euo pipefail

SCRIPT_DIRECTORY="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIRECTORY:h}"
BUILD_ROOT="${PROJECT_ROOT}/.build/app-package"
OUTPUT_DIRECTORY="${PROJECT_ROOT}/Release"
APP_BUNDLE="${OUTPUT_DIRECTORY}/BudgetFlow.app"
CONTENTS_DIRECTORY="${APP_BUNDLE}/Contents"
MACOS_DIRECTORY="${CONTENTS_DIRECTORY}/MacOS"
FRAMEWORKS_DIRECTORY="${CONTENTS_DIRECTORY}/Frameworks"
RESOURCES_DIRECTORY="${CONTENTS_DIRECTORY}/Resources"
PLUGINS_DIRECTORY="${CONTENTS_DIRECTORY}/PlugIns"
WIDGET_BUNDLE="${PLUGINS_DIRECTORY}/BudgetFlowWidget.appex"
WIDGET_CONTENTS_DIRECTORY="${WIDGET_BUNDLE}/Contents"
WIDGET_MACOS_DIRECTORY="${WIDGET_CONTENTS_DIRECTORY}/MacOS"
WIDGET_RESOURCES_DIRECTORY="${WIDGET_CONTENTS_DIRECTORY}/Resources"
MODULE_CACHE="${BUILD_ROOT}/module-cache"
SWIFT_COMPILER="$(xcrun --find swiftc)"
TARGET="arm64-apple-macosx14.0"

if [[ -n "${BUDGETFLOW_SDKROOT:-}" ]]; then
    SDK_ROOT="${BUDGETFLOW_SDKROOT}"
elif [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    # This machine currently has a newer compiler paired with an incompatible
    # default SDK. The installed 15.4 SDK is compatible with the compiler.
    SDK_ROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
else
    SDK_ROOT="$(xcrun --sdk macosx --show-sdk-path)"
fi

rm -rf "${BUILD_ROOT}" "${APP_BUNDLE}"
mkdir -p \
    "${MODULE_CACHE}" \
    "${MACOS_DIRECTORY}" \
    "${FRAMEWORKS_DIRECTORY}" \
    "${RESOURCES_DIRECTORY}" \
    "${WIDGET_MACOS_DIRECTORY}" \
    "${WIDGET_RESOURCES_DIRECTORY}"

CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" "${SWIFT_COMPILER}" \
    -emit-library \
    -emit-module \
    -parse-as-library \
    -swift-version 6 \
    -module-name BudgetCore \
    -sdk "${SDK_ROOT}" \
    -target "${TARGET}" \
    -Xlinker -install_name \
    -Xlinker @rpath/libBudgetCore.dylib \
    "${PROJECT_ROOT}"/Sources/BudgetCore/*.swift \
    -emit-module-path "${BUILD_ROOT}/BudgetCore.swiftmodule" \
    -o "${FRAMEWORKS_DIRECTORY}/libBudgetCore.dylib"

CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" "${SWIFT_COMPILER}" \
    -swift-version 6 \
    -sdk "${SDK_ROOT}" \
    -target "${TARGET}" \
    -I "${BUILD_ROOT}" \
    -L "${FRAMEWORKS_DIRECTORY}" \
    -lBudgetCore \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks \
    "${PROJECT_ROOT}"/Sources/BudgetFlow/*.swift \
    "${PROJECT_ROOT}"/Sources/BudgetFlow/Components/*.swift \
    "${PROJECT_ROOT}"/Sources/BudgetFlow/Views/*.swift \
    -o "${MACOS_DIRECTORY}/BudgetFlow"

CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" "${SWIFT_COMPILER}" \
    -parse-as-library \
    -application-extension \
    -swift-version 6 \
    -sdk "${SDK_ROOT}" \
    -target "${TARGET}" \
    -I "${BUILD_ROOT}" \
    -L "${FRAMEWORKS_DIRECTORY}" \
    -lBudgetCore \
    -Xlinker -rpath \
    -Xlinker @executable_path/../../../../Frameworks \
    "${PROJECT_ROOT}"/Sources/BudgetFlowWidget/*.swift \
    -o "${WIDGET_MACOS_DIRECTORY}/BudgetFlowWidget"

cp "${PROJECT_ROOT}/Packaging/Info.plist" "${CONTENTS_DIRECTORY}/Info.plist"
cp "${PROJECT_ROOT}/Packaging/WidgetInfo.plist" "${WIDGET_CONTENTS_DIRECTORY}/Info.plist"
cp "${PROJECT_ROOT}/Sources/BudgetFlow/Resources/BudgetFlow.icns" "${RESOURCES_DIRECTORY}/BudgetFlow.icns"
cp "${PROJECT_ROOT}/Sources/BudgetFlow/Resources/BudgetFlowIcon.png" "${RESOURCES_DIRECTORY}/BudgetFlowIcon.png"
cp "${PROJECT_ROOT}/Sources/BudgetFlow/Resources/BudgetFlowIcon.png" \
    "${WIDGET_RESOURCES_DIRECTORY}/BudgetFlowIcon.png"

codesign --force --sign - "${FRAMEWORKS_DIRECTORY}/libBudgetCore.dylib"
codesign --force --sign - \
    --entitlements "${PROJECT_ROOT}/Packaging/BudgetFlowWidget.entitlements" \
    "${WIDGET_BUNDLE}"
codesign --force --sign - \
    --entitlements "${PROJECT_ROOT}/Packaging/BudgetFlow.entitlements" \
    "${APP_BUNDLE}"
codesign --verify --deep --strict "${APP_BUNDLE}"
plutil -lint "${CONTENTS_DIRECTORY}/Info.plist"
plutil -lint "${WIDGET_CONTENTS_DIRECTORY}/Info.plist"

echo "Built ${APP_BUNDLE}"
