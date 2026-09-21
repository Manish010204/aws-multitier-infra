#!/bin/bash
set -e

# ─────────────────────────────────────────────
# EC2 User Data Script
# Runs automatically when EC2 first boots
# Installs Nginx + serves a custom page
# ─────────────────────────────────────────────

# Update packages
yum update -y

# Install nginx
yum install -y nginx

# Get instance metadata
# WHY: Shows which instance/AZ served request
# Great for proving load balancing works
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create custom HTML page
cat > /usr/share/nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Multi-Tier AWS — Manish Thakur</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      background: #0d1117;
      color: #e6edf3;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 12px;
      padding: 40px;
      max-width: 480px;
      width: 90%;
    }
    .badge {
      display: inline-block;
      background: rgba(86,211,100,0.15);
      color: #56d364;
      border: 1px solid rgba(86,211,100,0.3);
      border-radius: 20px;
      padding: 4px 14px;
      font-size: 12px;
      margin-bottom: 20px;
    }
    h1 { color: #f78166; font-size: 22px; margin-bottom: 24px; }
    .row {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #30363d;
      font-size: 13px;
    }
    .row:last-child { border-bottom: none; }
    .label { color: #8b949e; }
    .value { color: #79c0ff; font-weight: bold; }
    .footer {
      margin-top: 24px;
      font-size: 11px;
      color: #3d444d;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✅ HEALTHY — ALB Target</div>
    <h1>Multi-Tier AWS Infrastructure</h1>
    <div class="row">
      <span class="label">Instance ID</span>
      <span class="value">$INSTANCE_ID</span>
    </div>
    <div class="row">
      <span class="label">Availability Zone</span>
      <span class="value">$AZ</span>
    </div>
    <div class="row">
      <span class="label">Private IP</span>
      <span class="value">$LOCAL_IP</span>
    </div>
    <div class="row">
      <span class="label">Subnet Tier</span>
      <span class="value">Private App Subnet</span>
    </div>
    <div class="row">
      <span class="label">Public IP</span>
      <span class="value">None — Protected by ALB</span>
    </div>
    <div class="row">
      <span class="label">Built by</span>
      <span class="value">Manish Kumar Thakur</span>
    </div>
    <div class="footer">
      Reload page to see different AZ — proving load balancing works
    </div>
  </div>
</body>
</html>
EOF

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Log completion
echo "✅ User data script completed successfully" >> /var/log/user-data.log