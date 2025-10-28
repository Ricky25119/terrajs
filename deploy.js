import { execSync } from "child_process";
import path from "path";

const tfDir = path.join(process.cwd(), "main");

try {
  console.log(" Applying Terraform plan...");
  execSync(`terraform -chdir=${tfDir} apply -auto-approve tfplan`, {
    stdio: "inherit"
  });
  console.log(" Terraform apply completed!");
} catch (err) {
  console.error(" Terraform apply failed:", err.message);
  process.exit(1);
}
