# Pinohub Main Infrastructure

This stack manages the shared infrastructure for `pinohub.com` domain. It creates the Route 53 hosted zone, ACM certificate, and SES email identity that will be used by all applications hosted under `pinohub.com`.

**Important:** This stack is **stage-agnostic**. The CloudFormation stack name is `pinohub-main-infrastructure` (no stage suffix), and all SSM parameters and CloudFormation exports are shared across all environments (dev, prod, etc.).

## What This Stack Creates

1. **Route 53 Hosted Zone** for `pinohub.com`
   - This is created **ONCE** and shared across all applications
   - Other stacks reference this hosted zone to create DNS records

2. **ACM Certificate** for `pinohub.com` subdomains
   - Uses wildcard certificate (`*.pinohub.com`) to cover all subdomains
   - Must be in `us-east-1` region (CloudFront requirement)
   - Used by CloudFront distributions for HTTPS
   - **Manual validation** - validation CNAME records must be created manually in DNS provider (Porkbun or wherever DNS is managed)

3. **SES Email Identity** for `pinohub.com`
   - Allows sending emails from any address @pinohub.com (e.g., noreply@pinohub.com, support@pinohub.com)
   - DKIM signing enabled with 2048-bit RSA keys
   - SES Configuration Set for email tracking and reputation management

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
   - AWS profile `pinohub` must be configured
   - Configure with: `aws configure --profile pinohub`
2. **Serverless Framework** installed globally or locally
3. **Domain registered** at Porkbun (or any registrar)
4. **AWS Permissions** for:
   - Route 53 (create hosted zones, manage DNS)
   - ACM (request certificates)
   - SES (create email identities)
   - CloudFormation (create/update stacks)

## Initial Setup

### 1. Configure AWS Profile

Ensure the `pinohub` AWS profile is configured:

```bash
aws configure --profile pinohub
```

Or verify it exists:
```bash
aws configure list-profiles
```

### 2. Install Dependencies

```bash
cd pinohub
npm install
```

### 3. Deploy the Stack

**Use npm scripts**:

```bash
# Set AWS profile first
export AWS_PROFILE=pinohub  # Linux/Mac/WSL
# OR
$env:AWS_PROFILE="pinohub"  # Windows PowerShell

# Then deploy
npm run deploy:dev
npm run deploy:prod
```

### 4. Certificate Validation

**IMPORTANT:** DomainValidationOptions with HostedZoneId is NOT specified to avoid conflicts with existing validation records. If creating a new certificate, you'll need to create the validation CNAME records manually in your DNS provider (Porkbun or wherever DNS is managed).

**Check certificate validation status:**
```bash
# Get certificate ARN
CERT_ARN=$(aws acm list-certificates --region us-east-1 --profile pinohub \
  --query 'CertificateSummaryList[?contains(DomainName, `pinohub.com`)].CertificateArn' \
  --output text)

# Check status
aws acm describe-certificate --region us-east-1 --profile pinohub \
  --certificate-arn "$CERT_ARN" \
  --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus}'
```

### 5. (Optional) Get Route 53 Name Servers

If you want to move DNS management to Route 53 later, you can get the name servers:

```bash
npm run info:dev
```

Or check the stack outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name pinohub-main-infrastructure \
  --query 'Stacks[0].Outputs[?OutputKey==`PinohubHostedZoneNameServers`].OutputValue' \
  --output text
```

**Note:** You don't need to move name servers to Route 53 for certificate validation to work. The validation works by creating CNAME records in your DNS provider.

## SSM Parameter Store Parameters

This stack creates SSM Parameter Store parameters that can be accessed by any AWS service or application. This provides unified resource sharing across all company applications.

### Available Parameters

All parameters are **stage-agnostic** (shared across all environments) and prefixed with `/pinohub/`:

- **`/pinohub/hosted-zone-id`** - Route 53 Hosted Zone ID (shared across all stages)
- **`/pinohub/hosted-zone-name-servers`** - Route 53 Name Servers (comma-separated string, shared across all stages)
- **`/pinohub/certificate-arn`** - ACM Certificate ARN (shared across all stages)
- **`/pinohub/domain-name`** - Domain name (pinohub.com, shared across all stages)
- **`/pinohub/ses-identity-arn`** - SES Email Identity ARN (shared across all stages)
- **`/pinohub/ses-identity-name`** - SES Email Identity name (pinohub.com, shared across all stages)

**Note**: These parameters are stage-agnostic because the hosted zone, certificate, and SES identity are shared resources used by all environments (dev, prod, etc.).

### Usage in Serverless Framework

```yaml
custom:
  pinohubHostedZoneId: ${ssm:/pinohub/hosted-zone-id}
  pinohubCertificateArn: ${ssm:/pinohub/certificate-arn}
  pinohubDomainName: ${ssm:/pinohub/domain-name}
  pinohubSESIdentityArn: ${ssm:/pinohub/ses-identity-arn}
```

### Usage in AWS CLI

```bash
# Get hosted zone ID
aws ssm get-parameter --name "/pinohub/hosted-zone-id" --query 'Parameter.Value' --output text

# Get certificate ARN
aws ssm get-parameter --name "/pinohub/certificate-arn" --query 'Parameter.Value' --output text

# Get SES identity ARN
aws ssm get-parameter --name "/pinohub/ses-identity-arn" --query 'Parameter.Value' --output text

# Get name servers (comma-separated string)
aws ssm get-parameter --name "/pinohub/hosted-zone-name-servers" --query 'Parameter.Value' --output text
```

### Usage in Lambda Functions

```javascript
const AWS = require('aws-sdk');
const ssm = new AWS.SSM();

// Stage-agnostic - same parameter for all environments
const hostedZoneId = await ssm.getParameter({
  Name: '/pinohub/hosted-zone-id'
}).promise();

const sesIdentityArn = await ssm.getParameter({
  Name: '/pinohub/ses-identity-arn'
}).promise();
```

## Stack Outputs

This stack also exports the following values via CloudFormation (for backward compatibility):

### PinohubHostedZoneId
- **Export Name**: `pinohub-main-infrastructure-pinohub-hosted-zone-id` (stage-agnostic)
- **SSM Parameter**: `/pinohub/hosted-zone-id` (stage-agnostic)
- **Usage**: Reference this in Route 53 record sets
- **Example (SSM)**: `${ssm:/pinohub/hosted-zone-id}`
- **Example (CF Export)**: `!ImportValue pinohub-main-infrastructure-pinohub-hosted-zone-id`

### PinohubCertificateArn
- **Export Name**: `pinohub-main-infrastructure-pinohub-certificate-arn` (stage-agnostic)
- **SSM Parameter**: `/pinohub/certificate-arn` (stage-agnostic)
- **Usage**: Use in CloudFront distribution ViewerCertificate
- **Example (SSM)**: `${ssm:/pinohub/certificate-arn}`

### PinohubDomainName
- **Export Name**: `pinohub-main-infrastructure-pinohub-domain-name` (stage-agnostic)
- **SSM Parameter**: `/pinohub/domain-name` (stage-agnostic)
- **Usage**: Reference the domain name
- **Value**: `pinohub.com`
- **Example (SSM)**: `${ssm:/pinohub/domain-name}`

### PinohubSESIdentityArn
- **Export Name**: `pinohub-main-infrastructure-pinohub-ses-identity-arn` (stage-agnostic)
- **SSM Parameter**: `/pinohub/ses-identity-arn` (stage-agnostic)
- **Usage**: Reference SES identity for email sending
- **Example (SSM)**: `${ssm:/pinohub/ses-identity-arn}`

## Using in Other Stacks

### Example: Application Stack

In your application's `serverless.yml`, import the values:

```yaml
custom:
  # Import from pinohub-main-infra stack (stage-agnostic parameters)
  pinohubHostedZoneId: ${ssm:/pinohub/hosted-zone-id}
  pinohubCertificateArn: ${ssm:/pinohub/certificate-arn}
  pinohubDomainName: ${ssm:/pinohub/domain-name}

resources:
  Resources:
    # Route 53 A Record pointing to CloudFront
    PinohubARecord:
      Type: AWS::Route53::RecordSet
      Properties:
        HostedZoneId: ${self:custom.pinohubHostedZoneId}
        Name: app-dev.${self:custom.pinohubDomainName}
        Type: A
        AliasTarget:
          DNSName: !GetAtt CloudFrontDistribution.DomainName
          HostedZoneId: Z2FDTNDATAQYW2  # CloudFront hosted zone ID
    
    # CloudFront Distribution with custom domain
    CloudFrontDistribution:
      Properties:
        DistributionConfig:
          Aliases:
            - app-dev.${self:custom.pinohubDomainName}
          ViewerCertificate:
            AcmCertificateArn: ${self:custom.pinohubCertificateArn}
            SslSupportMethod: sni-only
            MinimumProtocolVersion: TLSv1.2_2021
```

## Important Notes

### ⚠️ One Hosted Zone Per Domain
- **You CANNOT create multiple hosted zones for the same domain**
- This stack creates the hosted zone **ONCE**
- All other stacks must **reference** this hosted zone, not create a new one

### 🔒 Certificate Region
- ACM certificate **MUST** be in `us-east-1` for CloudFront
- This stack is configured to deploy in `us-east-1` region

### 📍 Subdomain Approach
- This stack uses a **wildcard certificate** (`*.pinohub.com`) for subdomain support
- Applications use subdomains like `app-dev.pinohub.com`
- Create CNAME records at your DNS provider pointing subdomains to CloudFront distributions
- Example: `app-dev.pinohub.com` → `d1234567890.cloudfront.net`

### 🔄 Stack Dependencies
- Other stacks depend on this stack
- Deploy this stack **FIRST** before deploying application stacks
- If you remove this stack, all dependent stacks will fail

### 📧 SES Email Identity
- The SES identity allows sending from any @pinohub.com address
- DKIM records can be added to Route 53 for better email deliverability
- SES Configuration Set is created for email tracking and reputation management

## Commands

### Deploy
```bash
# Development
npm run deploy:dev

# Production
npm run deploy:prod

# Custom stage
serverless deploy --stage staging
```

### Get Stack Information
```bash
# Development
npm run info:dev

# Production
npm run info:prod
```

### Remove Stack
```bash
# ⚠️ WARNING: Only remove if you're sure no other stacks depend on it
npm run remove:dev
```

## Troubleshooting

### Certificate Not Validating
1. **Wait longer** - Validation typically takes 5-30 minutes, but can take up to 72 hours
2. **Check validation records** - You need to create CNAME records manually in your DNS provider:
   ```bash
   # Get certificate ARN
   CERT_ARN=$(aws acm list-certificates --region us-east-1 --profile pinohub \
     --query 'CertificateSummaryList[?contains(DomainName, `pinohub.com`)].CertificateArn' \
     --output text)
   
   # Get validation records
   aws acm describe-certificate --region us-east-1 --profile pinohub \
     --certificate-arn "$CERT_ARN" \
     --query 'Certificate.DomainValidationOptions[*].ResourceRecord'
   ```
3. **Create CNAME records** in your DNS provider (Porkbun) with the values from the command above
4. **If validation times out** (after 72 hours), the certificate request will be deleted. Redeploy the stack to create a new certificate request.

### Cannot Import Values in Other Stacks
1. Ensure this stack is deployed first
2. Check stack names match (case-sensitive)
3. Verify stage names match (dev, prod, etc.)
4. Check CloudFormation exports:
   ```bash
   aws cloudformation list-exports \
     --query "Exports[?Name=='pinohub-main-infrastructure-pinohub-hosted-zone-id']"
   ```

### Hosted Zone Already Exists
If you get an error that the hosted zone already exists:
1. Check if it was created manually in Route 53 console
2. If so, you can either:
   - Delete the existing hosted zone and redeploy this stack
   - Or reference the existing hosted zone ID in your stacks (not recommended)

## Cost

- **Route 53 Hosted Zone**: ~$0.50/month
- **ACM Certificate**: FREE
- **SES Identity**: FREE (pay only for emails sent)
- **Total**: ~$0.50/month + email sending costs

## Next Steps

After deploying this stack:

1. ✅ Create certificate validation CNAME records in your DNS provider
2. ✅ Wait for certificate validation (5-30 minutes)
3. ✅ Deploy application stacks (e.g., your applications)
4. ✅ Create CNAME records at DNS provider for subdomains (e.g., `app-dev.pinohub.com` → CloudFront)
5. ✅ Configure applications with subdomain base paths
6. ✅ Test domain access
7. ✅ (Optional) Add DKIM records to Route 53 for better email deliverability

## Support

For issues or questions:
- Check CloudFormation stack events in AWS Console
- Review Route 53 hosted zone in AWS Console
- Check ACM certificate status in AWS Console (us-east-1 region)
- Check SES identity status in AWS Console








