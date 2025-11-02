import fs from "fs";
import yaml from "js-yaml";
import path from "path";

// Directory where config files are stored
const configDir = path.join(process.cwd(), "config");

// Get all config files matching the pattern config-*.yml
const getConfigFiles = () => {
  try {
    return fs.readdirSync(configDir)
      .filter(file => file.startsWith('config-') && file.endsWith('.yml'))
      .sort(); // Sort to ensure consistent order
  } catch (err) {
    console.error('Error reading config directory:', err);
    return [];
  }
};

// Helper function to merge configs with special handling for arrays
function mergeConfigs(target, source) {
  if (!source) return target;
  const result = { ...target };
  
  Object.keys(source).forEach(key => {
    if (Array.isArray(source[key])) {
      // Concatenate arrays
      result[key] = [...(result[key] || []), ...source[key]];
    } else if (typeof source[key] === 'object') {
      // Recursively merge nested objects
      result[key] = mergeConfigs(result[key] || {}, source[key]);
    } else {
      // Replace primitive values
      result[key] = source[key];
    }
  });
  
  return result;
}

let config = {};
try {
  // Look for specific config files first
  const specificConfigs = ['config-user.yml', 'config-groups.yml'];
  const defaultConfig = 'config.yml';
  
  // Get any additional config files matching the pattern
  const configFiles = getConfigFiles();
  
  // Combine specific configs with discovered configs, ensure no duplicates
  const allConfigs = [...new Set([defaultConfig, ...specificConfigs, ...configFiles])];
  
  // Load and merge all found configs
  for (const configFile of allConfigs) {
    const configPath = path.join(configDir, configFile);
    if (fs.existsSync(configPath)) {
      const fileContents = fs.readFileSync(configPath, "utf8");
      const configData = yaml.load(fileContents);
      
      // Merge arrays instead of replacing them
      config = mergeConfigs(config, configData);
      console.log(`Loaded config from ${configFile}`);
    }
  }
  console.log("Loaded YAML config successfully");
} catch (e) {
  console.error("Failed to load config:", e.message);
  process.exit(1);
}

// Terraform does not accept arrays directly via CLI - so we'll serialize to JSON
export const terraformVars = {
  location: config.location,
  pim_users: JSON.stringify(config.pim_users || []),
  pim_groups: JSON.stringify(config.pim_groups || [])
};
