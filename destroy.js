import { execSync } from "child_process";
import path from "path";
import { terraformVars } from "./constant.js";

const tfDir = path.join(process.cwd(), "main");

try {
  console.log(" Destroying Terraform resources...");

  const varFlags = Object.entries(terraformVars)
    .map(([key, value]) => {
      if (key === "pim_users") {
        // Escape inner quotes for JSON safely
        const escapedValue = value.replace(/"/g, '\\"');
        return `-var ${key}="${escapedValue}"`;
      } else {
        return `-var ${key}="${value}"`;
      }
    })
    .join(" ");

  console.log(" Terraform command:", `terraform -chdir=${tfDir} destroy -auto-approve ${varFlags}`);

  execSync(`terraform -chdir=${tfDir} destroy -auto-approve ${varFlags}`, {
    stdio: "inherit"
  });

  console.log(" Terraform destroy completed!");
} catch (err) {
  console.error(" Terraform destroy failed:", err.message);
  process.exit(1);
}
