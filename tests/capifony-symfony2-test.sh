#!/usr/bin/env roundup
#
# capifony-symfony2-test.sh | William Durand <william.durand1@gmail.com>

describe "Capifony::Symfony2"

TESTS_DIR="tests"
FIXTURES_YAML_CONFIG="fixtures/config.yml"

before() {
    mkdir $TESTS_DIR
    cp $FIXTURES_YAML_CONFIG "$TESTS_DIR/test"
}

after() {
    rm -rf $TESTS_DIR
}

it_replaces_asset_version() {
    expected_content=$(cat <<EOF
framework:
    esi:             { enabled: true }
    translator:      { fallback: %locale% }
    secret:          %secret%
    router:
        resource: "%kernel.root_dir%/config/routing.yml"
        strict_requirements: %kernel.debug%
    form:            true
    csrf_protection: true
    validation:      { enable_annotations: true }
    templating:      { engines: ['twig'] } # assets_version: d7cedcc
    default_locale:  %locale%
    trust_proxy_headers: false # Whether or not the Request object should trust proxy headers (X_FORWARDED_FOR/HTTP_CLIENT_IP)
    session:         ~
    templating:
        assets_version:       d7cedcc
EOF)

    sed -i -e 's/\(assets_version:[ ]*\)\([a-zA-Z0-9_]*\)\(.*\)$/\1d7cedcc\3/g' "$TESTS_DIR/test"

    result=`cat $TESTS_DIR/test`
    test "$expected_content" "=" "$result"
}

it_replaces_asset_version_with_quotes() {
    expected_content=$(cat <<EOF
framework:
    esi:             { enabled: true }
    translator:      { fallback: %locale% }
    secret:          %secret%
    router:
        resource: "%kernel.root_dir%/config/routing.yml"
        strict_requirements: %kernel.debug%
    form:            true
    csrf_protection: true
    validation:      { enable_annotations: true }
    templating:      { engines: ['twig'] } # assets_version: foobar
    default_locale:  %locale%
    trust_proxy_headers: false # Whether or not the Request object should trust proxy headers (X_FORWARDED_FOR/HTTP_CLIENT_IP)
    session:         ~
    templating:
        assets_version:       foobar
EOF)

    sed -i -e 's/\(assets_version:[ ]*\)\([a-zA-Z0-9_]*\)\(.*\)$/\1d7cedcc\3/g' "$TESTS_DIR/test"
    sed -i -e 's/\(assets_version:[ ]*\)\([a-zA-Z0-9_]*\)\(.*\)$/\1foobar\3/g' "$TESTS_DIR/test"

    result=`cat $TESTS_DIR/test`
    test "$expected_content" "=" "$result"
}
