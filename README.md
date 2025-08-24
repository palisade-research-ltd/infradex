# infrastructure

## Terraform

Log in into terraform service.

```shell
terraform login
```

Start a terraform project if not already.

```shell
terraform init
```

Then, with the existing code, it can be modified, formatted and have a plan exercise to see what elements would be needed to create.

```shell
terraform fmt & terraform plan
```

If everything is Ok, the the final step is to apply the plan

```shell
terraform apply
```
