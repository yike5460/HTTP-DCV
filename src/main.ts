import { App, Stack, StackProps, aws_ec2, aws_ecs, aws_ecs_patterns, aws_iam} from 'aws-cdk-lib';
import { Construct } from 'constructs';
// import { AwsSolutionsChecks } from 'cdk-nag';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);
    // https://docs.aws.amazon.com/cdk/api/latest/docs/aws-ecs-patterns-readme.html

    // vpc for ecs cluster with fargate
    const vpc = new aws_ec2.Vpc(this, 'Vpc', {
      maxAzs: 2,
    });

    // ecs cluster with fargate
    const cluster = new aws_ecs.Cluster(this, 'Cluster', {
      clusterName: 'my-cluster',
      vpc: vpc,
    });

    // add acm permission (import certs) to ecs task role
    const taskRole = new aws_iam.Role(this, 'TaskRole', {
      assumedBy: new aws_iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });
    taskRole.addToPolicy(new aws_iam.PolicyStatement({
      resources: ['*'],
      // acm all write permission
      actions: 
        ["acm:DeleteCertificate",
        "acm:ResendValidationEmail",
        "acm:RequestCertificate",
        "acm:PutAccountConfiguration",
        "acm:UpdateCertificateOptions",
        "acm:ImportCertificate",
        "acm:RenewCertificate"],
    }));

    const loadBalancedFargateService = new aws_ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Service', {
      cluster,
      memoryLimitMiB: 1024,
      desiredCount: 1,
      cpu: 512,
      taskImageOptions: {
        image: aws_ecs.ContainerImage.fromAsset('src/containers'),
        // image: aws_ecs.ContainerImage.fromRegistry('public.ecr.aws/p9r6s5p7/certbot-server:latest'),
        taskRole: taskRole,
      },
    });

    loadBalancedFargateService.targetGroup.healthCheck = {
      path: '/health',
      // interval: cdk.Duration.seconds(60),
      // timeout: cdk.Duration.seconds(5),
      // healthyHttpCodes: '200',
    };

    const scalableTarget = loadBalancedFargateService.service.autoScaleTaskCount({
      minCapacity: 1,
      maxCapacity: 20,
    });

    scalableTarget.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 50,
    });

    scalableTarget.scaleOnMemoryUtilization('MemoryScaling', {
      targetUtilizationPercent: 50,
    });

  }
}

// for development, use account/region from cdk cli
const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

const app = new App();

new MyStack(app, 'projenDemo-dev', { env: devEnv });
// Aspects.of(app).add(new AwsSolutionsChecks({verbose:true}));

app.synth();