#!/usr/bin/env bash
# Create a new Ansible collection from template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DEV_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$ANSIBLE_DEV_DIR")"
TEMPLATE_DIR="$ANSIBLE_DEV_DIR/templates/collection-template"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <collection-name> [description]"
    echo ""
    echo "Creates a new Ansible collection from the template."
    echo ""
    echo "Arguments:"
    echo "  collection-name    Name of the collection (lowercase, alphanumeric and underscores only)"
    echo "  description        Optional description of the collection"
    echo ""
    echo "Example:"
    echo "  $0 monitoring 'Monitoring and alerting infrastructure'"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

COLLECTION_NAME="$1"
COLLECTION_DESCRIPTION="${2:-Ansible collection for $COLLECTION_NAME}"

# Validate collection name
if ! [[ "$COLLECTION_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}Error: Collection name must contain only lowercase letters, numbers, and underscores${NC}"
    exit 1
fi

if [[ "$COLLECTION_NAME" =~ ^[0-9_] ]]; then
    echo -e "${RED}Error: Collection name cannot start with a number or underscore${NC}"
    exit 1
fi

COLLECTION_DIR="$REPO_ROOT/$COLLECTION_NAME"

# Check if collection already exists
if [ -d "$COLLECTION_DIR" ]; then
    echo -e "${RED}Error: Collection '$COLLECTION_NAME' already exists at $COLLECTION_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Creating new collection: tenx.$COLLECTION_NAME${NC}"
echo "Description: $COLLECTION_DESCRIPTION"
echo ""

# Copy template
cp -r "$TEMPLATE_DIR" "$COLLECTION_DIR"

# Replace placeholders in galaxy.yml
sed -i '' "s/{{COLLECTION_NAME}}/$COLLECTION_NAME/g" "$COLLECTION_DIR/galaxy.yml"
sed -i '' "s/{{COLLECTION_DESCRIPTION}}/$COLLECTION_DESCRIPTION/g" "$COLLECTION_DIR/galaxy.yml"

# Default tags based on collection name
COLLECTION_TAGS="[]"
sed -i '' "s/{{COLLECTION_TAGS}}/$COLLECTION_TAGS/g" "$COLLECTION_DIR/galaxy.yml"

# Replace placeholders in README
sed -i '' "s/{{COLLECTION_NAME}}/$COLLECTION_NAME/g" "$COLLECTION_DIR/README.md"
sed -i '' "s/{{COLLECTION_DESCRIPTION}}/$COLLECTION_DESCRIPTION/g" "$COLLECTION_DIR/README.md"

echo -e "${GREEN}✓ Collection structure created${NC}"
echo ""
echo "Collection created at: $COLLECTION_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $COLLECTION_NAME"
echo "  2. Edit galaxy.yml to add tags and dependencies"
echo "  3. Update README.md with detailed documentation"
echo "  4. Create roles using: ../.ansible-dev/scripts/new-role.sh $COLLECTION_NAME <role-name>"
echo ""
echo -e "${YELLOW}Don't forget to update the root README.md to include your new collection!${NC}"
