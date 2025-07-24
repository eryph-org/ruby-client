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
    
    console.log(`Syncing compute-client version to ${version}`);
    
    // Update Ruby version file
    const versionFilePath = path.join(__dirname, '..', '..', 'lib', 'eryph', 'version.rb');
    const versionFileContent = fs.readFileSync(versionFilePath, 'utf8');
    
    // Replace the VERSION constant
    const updatedContent = versionFileContent.replace(
      /(VERSION\s*=\s*["'])([^"']+)(["'])/,
      `$1${version}$3`
    );
    
    fs.writeFileSync(versionFilePath, updatedContent, 'utf8');
    console.log(`✅ Updated ${versionFilePath} to version ${version}`);
    
    // Also update gemspec dependency if compute client version changes
    // We need to ensure clientruntime dependency stays compatible
    const gemspecPath = path.join(__dirname, '..', '..', 'eryph-compute-client.gemspec');
    if (fs.existsSync(gemspecPath)) {
      const gemspecContent = fs.readFileSync(gemspecPath, 'utf8');
      
      // Extract major.minor version for dependency
      const [major, minor] = version.split('.');
      const dependencyVersion = `${major}.${minor}`;
      
      const updatedGemspec = gemspecContent.replace(
        /(s\.add_runtime_dependency\s+['"]eryph-clientruntime['"],\s*['"]~>\s*)([^'"]+)(['"])/,
        `$1${dependencyVersion}$3`
      );
      
      if (updatedGemspec !== gemspecContent) {
        fs.writeFileSync(gemspecPath, updatedGemspec, 'utf8');
        console.log(`✅ Updated gemspec dependency to ~> ${dependencyVersion}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Failed to sync compute-client version:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  syncVersion();
}

module.exports = { syncVersion };