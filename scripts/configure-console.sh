#!/bin/bash
set -e

NAMESPACE="events"

echo "Configuring Redpanda Console to use Schema Registry..."

# Create console config with schema registry support
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: redpanda-console-config
  namespace: $NAMESPACE
data:
  config.yml: |
    kafka:
      brokers:
        - redpanda:9092
      schemaRegistry:
        enabled: true
        urls:
          - http://redpanda:8081
EOF

echo "✓ ConfigMap created"

# Check if volumes already exist in the deployment
if kubectl get deployment redpanda-console -n $NAMESPACE -o json | grep -q '"volumes"'; then
  echo "Deployment already has volumes, updating..."

  # Update existing deployment
  kubectl patch deployment redpanda-console -n $NAMESPACE --type='strategic' -p='
spec:
  template:
    spec:
      volumes:
        - name: config
          configMap:
            name: redpanda-console-config
      containers:
        - name: console
          volumeMounts:
            - name: config
              mountPath: /tmp/config.yml
              subPath: config.yml
'
else
  echo "Adding volumes to deployment..."

  # Add volumes for the first time
  kubectl patch deployment redpanda-console -n $NAMESPACE --type='json' -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/volumes",
      "value": [
        {
          "name": "config",
          "configMap": {
            "name": "redpanda-console-config"
          }
        }
      ]
    },
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts",
      "value": [
        {
          "name": "config",
          "mountPath": "/tmp/config.yml",
          "subPath": "config.yml"
        }
      ]
    }
  ]'
fi

echo "✓ Deployment patched"
echo ""
echo "Waiting for console to restart..."
kubectl rollout status deployment/redpanda-console -n $NAMESPACE --timeout=120s

echo ""
echo "✓ Console configured! It will now deserialize protobuf messages using the Schema Registry."
echo ""
echo "Access the console at: http://ondash:30011"
echo "Navigate to Topics → chat-messages or upload-messages → Messages tab"
echo "You should now see properly deserialized JSON messages!"
