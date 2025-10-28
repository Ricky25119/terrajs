import { execSync } from "child_process";
import path from "path";
import { terraformVars } from "./constant.js";

const tfDir = path.join(process.cwd(), "main");

try {
  console.log(" Running Terraform INIT...");
  execSync(`terraform -chdir=${tfDir} init -input=false`, { stdio: "inherit" });

  console.log(" Running Terraform VALIDATE...");
  execSync(`terraform -chdir=${tfDir} validate`, { stdio: "inherit" });

  console.log(" Running Terraform PLAN...");

  const varFlags = Object.entries(terraformVars)
    .map(([key, value]) => {
  if (key === "pim_users") {
    // escape quotes for JSON safely
    const escapedValue = value.replace(/"/g, '\\"');
    return `-var ${key}="${escapedValue}"`;
  } else {
    return `-var ${key}="${value}"`;
  }
})
.join(" ");
    execSync(`terraform -chdir=${tfDir} plan -out=tfplan ${varFlags}`,{stdio: "inherit"});

  console.log(" Terraform plan completed successfully!");
} catch (err) {
  console.error(" Terraform test failed:", err.message);
  process.exit(1);
}
