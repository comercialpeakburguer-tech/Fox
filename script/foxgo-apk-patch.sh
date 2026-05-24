#!/usr/bin/env bash
set -Eeuo pipefail
python3 - <<'PY'
from pathlib import Path
import re
p = Path('pubspec.yaml')
s = p.read_text(encoding='utf-8')
s = re.sub(r'^version:.*$', 'version: 3.9.2+6', s, flags=re.M)
p.write_text(s, encoding='utf-8')
p = Path('lib/util/app_constants.dart')
s = p.read_text(encoding='utf-8')
s = s.replace('static const double appVersion = 3.8;', 'static const double appVersion = 3.9;')
s = s.replace('static const bool payInWevView = false;', 'static const bool payInWevView = true;')
p.write_text(s, encoding='utf-8')
print('Fox GO APK patch applied: 3.9.2+6')
PY
