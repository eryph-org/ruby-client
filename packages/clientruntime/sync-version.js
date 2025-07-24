#!/usr/bin/env node

/**
 * Sync version from package.json to Ruby version file
 * This script is run after changeset updates the package.json version
 */

const fs = require('fs');
const path = require('path');

function syncVersion() {
  try {
    // Read version from package.json
    const packageJsonPath = path.join(__dirname, 'package.json');
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    const version = packageJson.version;
    
    console.log(`Syncing clientruntime version to ${version}`);
    
    // Update Ruby version file
    const versionFilePath = path.join(__dirname, '..', '..', 'lib', 'eryph', 'clientruntime', 'version.rb');
    const versionFileContent = fs.readFileSync(versionFilePath, 'utf8');
    
    // Replace the VERSION constant
    const updatedContent = versionFileContent.replace(
      /(VERSION\s*=\s*["'])([^"']+)(["'])/,
      `$1${version}$3`
    );
    
    fs.writeFileSync(versionFilePath, updatedContent, 'utf8');
    console.log(`✅ Updated ${versionFilePath} to version ${version}`);
    
  } catch (error) {
    console.error('❌ Failed to sync clientruntime version:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  syncVersion();
}

module.exports = { syncVersion };