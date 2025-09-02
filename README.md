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

## AWS Keypair for EC2

> Provides an EC2 key pair resource. A key pair is used to control login access to EC2 instances. Currently this resource requires an existing user-supplied key pair, so it has to be created before hando using one of the options mentioned at the docs of AWS.

```shell
aws ec2 create-key-pair \
    --key-name infradex-key-pair \
    --key-type rsa \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > infradex-key-pair.pem
```

...and then change the permissions on the fiel

```shell
chmod 400 infradex-key-pair.pem
```

## Check DB

If `security group allows connection attemps from outside and/or from the IP where these would be run.

Ports open

```shell
netstat -tulpn | grep -E ":(8123|9000)"
```

HTTP Interface

```shell
curl http://EC2_PUBLIC_IP:8123/ping
```

Test a query

```shell
curl 'http://EC2_PUBLIC_IP:8123/?query=SELECT%201'
```

