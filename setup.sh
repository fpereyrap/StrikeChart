#!/bin/bash

# Strike Chart Setup Script
echo "🎯 Strike Chart Setup"
echo "===================="

# Get user's preferred bundle identifier
read -p "Enter your preferred bundle identifier (e.g., com.yourname.StrikeChart): " BUNDLE_ID

if [ -z "$BUNDLE_ID" ]; then
    echo "❌ Bundle identifier cannot be empty"
    exit 1
fi

WIDGET_BUNDLE_ID="${BUNDLE_ID}.HabitWidgetExtension"
APP_GROUP="group.${BUNDLE_ID}"

echo "📝 Configuration:"
echo "   Main App: $BUNDLE_ID"
echo "   Widget: $WIDGET_BUNDLE_ID" 
echo "   App Group: $APP_GROUP"
echo ""

# Update entitlements files
echo "🔧 Updating entitlements..."

# Update main app entitlements
sed -i '' "s/group\.com\.yourname\.StrikeChart/$APP_GROUP/g" "StrikeChart/StrikeChart.entitlements"

# Update widget entitlements  
sed -i '' "s/group\.com\.yourname\.StrikeChart/$APP_GROUP/g" "HabitWidgetExtension/HabitWidgetExtension.entitlements"

# Update project file bundle identifiers
sed -i '' "s/com\.yourname\.StrikeChart\.HabitWidgetExtension/$WIDGET_BUNDLE_ID/g" "StrikeChart.xcodeproj/project.pbxproj"
sed -i '' "s/com\.yourname\.StrikeChart/$BUNDLE_ID/g" "StrikeChart.xcodeproj/project.pbxproj"

# Update DataManager with new app group
sed -i '' "s/group\.com\.yourname\.StrikeChart/$APP_GROUP/g" "Shared/DataManager.swift"

# Update Widget with new app group
sed -i '' "s/group\.com\.yourname\.StrikeChart/$APP_GROUP/g" "HabitWidgetExtension/HabitWidget.swift"

echo "✅ Setup complete!"
echo ""
echo "📱 Next steps:"
echo "1. Open StrikeChart.xcodeproj in Xcode"
echo "2. Select your development team in Signing & Capabilities"
echo "3. Build and run on simulator or device"
echo ""
echo "🔗 Widget App Group: $APP_GROUP"
echo "   Make sure both main app and widget use this same App Group ID"