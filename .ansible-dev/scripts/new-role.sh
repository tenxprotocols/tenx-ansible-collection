#!/usr/bin/env bash
# Create a new Ansible role within a collection from template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DEV_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$ANSIBLE_DEV_DIR")"
TEMPLATE_DIR="$ANSIBLE_DEV_DIR/templates/role-template"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <collection-name> <role-name> [description]"
    echo ""
    echo "Creates a new Ansible role within a collection from the template."
    echo ""
    echo "Arguments:"
    echo "  collection-name    Name of the collection (must exist)"
    echo "  role-name          Name of the role (lowercase, alphanumeric and underscores only)"
    echo "  description        Optional description of the role"
    echo ""
    echo "Example:"
    echo "  $0 monitoring prometheus 'Installs and configures Prometheus'"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    usage
fi

COLLECTION_NAME="$1"
ROLE_NAME="$2"
ROLE_DESCRIPTION="${3:-Ansible role for $ROLE_NAME}"

# Validate collection name
if ! [[ "$COLLECTION_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}Error: Collection name must contain only lowercase letters, numbers, and underscores${NC}"
    exit 1
fi

# Validate role name
if ! [[ "$ROLE_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}Error: Role name must contain only lowercase letters, numbers, and underscores${NC}"
    exit 1
fi

if [[ "$ROLE_NAME" =~ ^[0-9_] ]]; then
    echo -e "${RED}Error: Role name cannot start with a number or underscore${NC}"
    exit 1
fi

COLLECTION_DIR="$REPO_ROOT/$COLLECTION_NAME"
ROLE_DIR="$COLLECTION_DIR/roles/$ROLE_NAME"

# Check if collection exists
if [ ! -d "$COLLECTION_DIR" ]; then
    echo -e "${RED}Error: Collection '$COLLECTION_NAME' does not exist at $COLLECTION_DIR${NC}"
    echo "Create it first using: $0/new-collection.sh $COLLECTION_NAME"
    exit 1
fi

# Create roles directory if it doesn't exist
mkdir -p "$COLLECTION_DIR/roles"

# Check if role already exists
if [ -d "$ROLE_DIR" ]; then
    echo -e "${RED}Error: Role '$ROLE_NAME' already exists in collection '$COLLECTION_NAME'${NC}"
    exit 1
fi

echo -e "${GREEN}Creating new role: tenx.$COLLECTION_NAME.$ROLE_NAME${NC}"
echo "Description: $ROLE_DESCRIPTION"
echo ""

# Copy template
cp -r "$TEMPLATE_DIR" "$ROLE_DIR"

# Replace placeholders in all files
find "$ROLE_DIR" -type f -exec sed -i '' "s/{{ROLE_NAME}}/$ROLE_NAME/g" {} +
find "$ROLE_DIR" -type f -exec sed -i '' "s/{{ROLE_DESCRIPTION}}/$ROLE_DESCRIPTION/g" {} +
find "$ROLE_DIR" -type f -exec sed -i '' "s/{{COLLECTION_NAME}}/$COLLECTION_NAME/g" {} +

echo -e "${GREEN}✓ Role structure created${NC}"
echo ""
echo "Role created at: $ROLE_DIR"
echo ""
echo "Files created:"
echo "  ├── README.md"
echo "  ├── defaults/main.yml"
echo "  ├── handlers/main.yml"
echo "  ├── meta/main.yml"
echo "  ├── tasks/main.yml"
echo "  ├── vars/main.yml"
echo "  ├── templates/"
echo "  └── files/"
echo ""
echo "Next steps:"
echo "  1. cd $COLLECTION_NAME/roles/$ROLE_NAME"
echo "  2. Edit tasks/main.yml to add your tasks"
echo "  3. Update defaults/main.yml with your default variables"
echo "  4. Update README.md with detailed documentation"
echo "  5. Add templates to templates/ directory if needed"
echo ""
echo -e "${YELLOW}Don't forget to update $COLLECTION_NAME/README.md to document your new role!${NC}"
