import fs from "fs";
import yaml from "js-yaml";
import path from "path";

const configPath = path.join(process.cwd(), "config", "config.yml");

let config = {};
try {
  const fileContents = fs.readFileSync(configPath, "utf8");
  config = yaml.load(fileContents);
  console.log(" Loaded YAML config successfully");
} catch (e) {
  console.error(" Failed to load config:", e.message);
  process.exit(1);
}

// Terraform does not accept arrays directly via CLI - so we’ll serialize to JSON
export const terraformVars = {
  location: config.location,
  pim_users: JSON.stringify(config.pim_users)
};
