#!/usr/bin/env bash
# Builds a tiny repo with a bloated AI branch, in the current directory.
# Usage: setup.sh [clean|failing|dirty]
set -euo pipefail
variant="${1:-clean}"
g() { git -c user.name=fixture -c user.email=fixture@example.com "$@"; }

git init -q -b master
git config user.name fixture && git config user.email fixture@example.com

cat > users.py <<'EOF'
USERS = [
    {"name": "Ada", "email": "ada@example.com", "status": "active"},
    {"name": "Bob", "email": "bob@example.com", "status": "inactive"},
    {"name": "Cy", "email": None, "status": "active"},
    {"name": "Di", "email": "di@example.com", "status": "active"},
]
EOF

cat > legacy.py <<'EOF'
def DoThing(x):  # sentinel-legacy
    Result = []
    for i in range(0, len(x)):
        if x[i] != None:
            Result.append(x[i])
        else:
            pass
    return Result
EOF

cat > test_users.py <<'EOF'
import unittest
from users import USERS


class TestUsers(unittest.TestCase):
    def test_has_users(self):
        self.assertEqual(len(USERS), 4)


if __name__ == "__main__":
    unittest.main()
EOF

cat > README.md <<'EOF'
# users

Sample user data.
EOF

echo "__pycache__/" > .gitignore

g add -A && g commit -qm "Initial commit"
g switch -qc ai/active-emails

cat >> users.py <<'EOF'


import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


@dataclass
class EmailConfig:
    include_inactive: bool = False
    skip_missing: bool = True


class UserEmailExtractor:
    """Extracts email addresses from a collection of users."""

    def __init__(self, users, config=None):
        self.users = users
        self.config = config or EmailConfig()

    def _is_eligible(self, user):
        if self.config.include_inactive:
            return True
        return user.get("status") == "active"

    def extract(self):
        logger.info("Extracting emails from %d users", len(self.users))
        result = []
        for user in self.users:
            if self._is_eligible(user):
                email = user.get("email")
                if email is not None or not self.config.skip_missing:
                    result.append(email)
        logger.info("Extracted %d emails", len(result))
        return result


def active_emails(users=None):
    return UserEmailExtractor(users if users is not None else USERS).extract()
EOF

expected='["ada@example.com", "di@example.com"]'
wrapper_expected="$expected"
[ "$variant" = failing ] && wrapper_expected='["ada@example.com", "bob@example.com"]'

cat > test_users.py <<EOF
import unittest
from users import USERS, UserEmailExtractor, EmailConfig, active_emails


class TestUsers(unittest.TestCase):
    def test_has_users(self):
        self.assertEqual(len(USERS), 4)


class TestUserEmailExtractor(unittest.TestCase):
    def test_extract_active(self):
        self.assertEqual(UserEmailExtractor(USERS).extract(), $expected)

    def test_default_config(self):
        self.assertFalse(EmailConfig().include_inactive)

    def test_active_emails(self):
        self.assertEqual(active_emails(), $wrapper_expected)


if __name__ == "__main__":
    unittest.main()
EOF

cat >> README.md <<'EOF'

## Email extraction architecture

The email extraction subsystem is built around a flexible, extensible design
that cleanly separates configuration from extraction logic.

### Components

- **EmailConfig**: a dataclass holding extraction settings.
  - `include_inactive`: when true, inactive users are included.
  - `skip_missing`: when true, users without an email are skipped.
- **UserEmailExtractor**: the core extraction engine. It accepts a list of
  users and an optional configuration object.
- **active_emails()**: a convenience wrapper around the extractor.

### Design principles

1. Separation of concerns: configuration is decoupled from behaviour.
2. Extensibility: new filters can be added by extending `_is_eligible`.
3. Observability: structured logging records each extraction run.

### Usage

    from users import active_emails
    emails = active_emails()

### Future work

- Pluggable filter strategies.
- Async extraction for large user sets.
EOF

g add -A && g commit -qm "Add active_emails: return the emails of active users"

if [ "$variant" = dirty ]; then
    echo "local note" >> README.md
fi
