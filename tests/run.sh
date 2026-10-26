#!/bin/sh
# Builds the example site with different settings and checks the output.
# Runs inside the pinned Hugo image (see .github/workflows/ci.yml).
set -eu
cd "$(dirname "$0")/../exampleSite"
fail=0
check() { # name, file, expected (fixed string), "absent" to expect no match
  if [ "${4:-}" = absent ]; then
    if grep -qF -- "$3" "$2"; then echo "FAIL $1: found $3"; fail=1; else echo "ok   $1"; fi
  else
    if grep -qF -- "$3" "$2"; then echo "ok   $1"; else echo "FAIL $1: missing $3"; grep -i privatus "$2" || true; fail=1; fi
  fi
}
build() { rm -rf public; hugo --quiet --config "$1" ; }

build hugo.toml
check "example config" public/index.html '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_EXAMPLE123" data-exclude="/drafts/*" data-modules="engage,auto"></script>'
check "event link" public/index.html '<a href="https://privatusanalytics.com" target="_blank" rel="noopener" data-privatus-event="Outbound clicked" data-privatus-prop-button_location="Home page" data-privatus-click="home.cta">Try <strong>Privatus Analytics</strong></a>'

build hugo.toml,../tests/cases/full.toml
check "all options" public/index.html '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_FULL99" data-allow-local="true" data-debug="true" data-domains="example.org,www.example.org" data-manual="true" data-mask="/users/*-&gt;/users/:id" data-modules="engage,vitals" data-props="x&#34; onload=&#34;alert(1)" data-spa="history"></script>'
check "only data- attributes" public/index.html 'onclick' absent

build hugo.toml,../tests/cases/nomodules.yaml
check "empty modules list (yaml)" public/index.html 'data-site="pa_NOMOD1" data-exclude="/drafts/*" data-modules=""></script>'

build hugo.toml,../tests/cases/badid.toml
check "invalid site id prints nothing" public/index.html 'privatusstats.com' absent

build hugo.toml,../tests/cases/noid.toml
check "empty site id prints nothing" public/index.html 'privatusstats.com' absent

rm -rf public
HUGO_PARAMS_PRIVATUSANALYTICS_SITEID=pa_FROMENV hugo --quiet
check "site id from environment" public/index.html 'data-site="pa_FROMENV"'

serve() { # config, output dir
  rm -rf "$2"
  hugo server --config "$1" --port 1414 --renderToMemory=false --destination "$2" --disableLiveReload >/dev/null 2>&1 &
  pid=$!
  i=0; while [ ! -f "$2/index.html" ] && [ $i -lt 50 ]; do sleep 0.2; i=$((i+1)); done
  sleep 0.5; kill $pid; wait $pid 2>/dev/null || true
}
serve hugo.toml /tmp/serve1
check "skipped on hugo server" /tmp/serve1/index.html 'privatusstats.com' absent
serve hugo.toml,../tests/cases/server.toml /tmp/serve2
check "enableOnServer" /tmp/serve2/index.html 'data-site="pa_SERVER1"'

rm -rf public
exit $fail
