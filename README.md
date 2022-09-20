# HTTP DCV Prototyping
This repo was intend to do a demo for projen, now it's been extend for usage of HTTP DCV prototyping

## Deployment

Command below will create Application Load Balancer attached with ECS Fargate Service, and the service will be deployed with the image from local assets.

```bash
npx projen deploy --force --require-approval never
```

Or you can use the public image directly from AWS Gallery.

```bash
# optional, check for latest image digest
docker pull public.ecr.aws/p9r6s5p7/certbot-server:latest
docker inspect public.ecr.aws/p9r6s5p7/certbot-server:latest --format='{{index .RepoDigests 0}}'
# execute on local/EC2/ECS Fargate
docker run -it -p 80:80 -p 8080:8080 -p 443:443 public.ecr.aws/p9r6s5p7/certbot-server:latest /bin/bash
```

## Test

Make sure your custom domain are pointed to (CNAME) the ALB DNS name, for example, if your domain is `cert.example.com` and want to issue certificates for such domain, you will first add <Application Load Balancer URL created in deployment> to your DNS CNAME record, then you can use the following command to test the service.

```bash
# trigger certbot to issue certificate
curl -i <Application Load Balancer URL created in deployment>/certbot -d 'server_name=cert.example.com' -d 'certbot_email=<your name>@example.com'

# output of the certificate in ECS Fargate
ls -al /etc/letsencrypt/live/cert.example.com/
total 4
drwxrwxrwx 2 root root  93 Sep 19 06:51 .
drwx------ 3 root root  44 Sep 19 06:51 ..
-rw-rw-rw- 1 root root 692 Sep 19 06:51 README
lrwxrwxrwx 1 root root  40 Sep 19 06:51 cert.pem -> ../../archive/cert.example.com/cert1.pem
lrwxrwxrwx 1 root root  41 Sep 19 06:51 chain.pem -> ../../archive/cert.example.com/chain1.pem
lrwxrwxrwx 1 root root  45 Sep 19 06:51 fullchain.pem -> ../../archive/cert.example.com/fullchain1.pem
lrwxrwxrwx 1 root root  43 Sep 19 06:51 privkey.pem -> ../../archive/cert.example.com/privkey1.pem

# check if the certificate been imported into ACM by console or CLI for specific domain name
aws acm list-certificates --region <region> --query 'CertificateSummaryList[?DomainName==`cert.example.com`].CertificateArn'
[
    "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
]
```

