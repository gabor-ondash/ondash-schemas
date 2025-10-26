# Versioning


# Tag versions semantically
```bash
git tag v1.0.0  # Initial release
git tag v1.1.0  # New field added (backward compatible)
git tag v2.0.0  # Breaking change
```

# Services pin to specific versions
```
# frontend/package.json
"@yourcompany/schemas": "^1.1.0"  # Allow patches
```
# For breaking changes, coordinate updates across services