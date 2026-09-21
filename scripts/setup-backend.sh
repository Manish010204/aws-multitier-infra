#!/bin/bash

# ─────────────────────────────────────────────
# Terraform Backend Setup Script
# Idempotent — safe to run multiple times
# ─────────────────────────────────────────────

set -e

BUCKET_NAME="manish-terraform-state-$(aws sts get-caller-identity --query Account --output text)"
REGION="ap-south-1"
DYNAMODB_TABLE="terraform-state-lock"

echo ""
echo "🚀 Setting up Terraform Backend..."
echo "   Bucket  : $BUCKET_NAME"
echo "   Region  : $REGION"
echo "   DynamoDB: $DYNAMODB_TABLE"
echo ""

# ── STEP 1: S3 Bucket ────────────────────────
echo "📦 Checking S3 bucket..."

# Check if bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "   ⏭️  Bucket already exists — skipping creation"
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
  echo "   ✅ Bucket created"
fi

# ── STEP 2: Versioning ───────────────────────
echo "🔄 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled
echo "   ✅ Versioning enabled"

# ── STEP 3: Block public access ──────────────
echo "🔒 Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "   ✅ Public access blocked"

# ── STEP 4: Encryption ───────────────────────
echo "🔐 Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "   ✅ Encryption enabled"

# ── STEP 5: DynamoDB ─────────────────────────
echo "🗄️  Checking DynamoDB table..."

# Check if table already exists
if aws dynamodb describe-table \
     --table-name "$DYNAMODB_TABLE" \
     --region "$REGION" 2>/dev/null; then
  echo "   ⏭️  Table already exists — skipping creation"
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions \
      AttributeName=LockID,AttributeType=S \
    --key-schema \
      AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "   ✅ DynamoDB table created"
fi

# ── DONE ─────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
echo "✅ Backend setup complete!"
echo ""
echo "📋 Your bucket name:"
echo "   $BUCKET_NAME"
echo "─────────────────────────────────────────"
echo ""