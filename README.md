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

...and then change the permissions on the file

```shell
chmod 400 infradex-key-pair.pem
```

## Connect to DB

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

## Launch Database

Using AWS CLI, check for detected EC2 instances locally: 

```shell
aws ec2 describe-instances | grep "PublicIp"
```

chose from the ones that appear, and execute a connection with SSH.

```shell
ssh -i ~/.ssh/aws-keys/infradex-key.pem ec2-user@54.197.249.246
```

then, within the ec2, verify docker containers running. 

```shell
docker ps -a
```

Try testing connectivity with a ping using `curl http://localhost:8123/ping` which should output a plain `Ok.`

## Connection using DBeaver

- Host: use the public DNS `ec2-34-233-65-252.compute-1.amazonaws.com`
- Port: `8123`
- Database/Schema: `operations`
- User: `default`

