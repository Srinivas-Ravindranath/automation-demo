from python_terraform import Terraform
import sys

class TerraformManager:
    def __init__(self, work_dir):
        """Initialize Terraform manager with the working directory."""
        self.work_dir = work_dir
        self.tf = Terraform(working_dir=work_dir)

    def init(self):
        """Initialize Terraform in the working directory."""
        print("Initializing Terraform...")
        return_code, output, error = self.tf.init()
        self._handle_errors(return_code, error, "Terraform init failed")
        print(output)
        return output

    def plan(self, plan_file="tfplan"):
        """Run Terraform plan and save the plan file."""
        print("Running Terraform plan...")
        return_code, output, error = self.tf.plan(out=plan_file)
        self._handle_errors(return_code, error, "Terraform plan failed")
        print(output)
        return output

    def apply(self):
        """Apply Terraform changes using the saved plan."""
        print("Applying Terraform changes...")
        return_code, output, error = self.tf.apply(skip_plan=True, auto_approve=True)
        self._handle_errors(return_code, error, "Terraform apply failed")
        print(output)
        return output

    def destroy(self):
        """Destroy Terraform-managed infrastructure."""
        print("Destroying Terraform-managed infrastructure...")
        return_code, output, error = self.tf.destroy(auto_approve=True)
        self._handle_errors(return_code, error, "Terraform destroy failed")
        print(output)
        return output

    def _handle_errors(self, return_code, error, message):
        """Handle errors by printing and exiting if needed."""
        if return_code != 0:
            print(f"{message}:\n{error}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    tf_directory = "./terraform"  # Change this to your Terraform directory