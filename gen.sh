#!/bin/bash

generator() {
    if command -v openapi-generator-cli &>/dev/null; then
        openapi-generator-cli "$@"
    else
        if [[ -x /usr/local/bin/docker-entrypoint.sh ]]; then
            /usr/local/bin/docker-entrypoint.sh "$@"
        else
            echo "Install openapi-generator-cli..." >&2
            exit 1
        fi

    fi
}

generate() {
    specification="${1:-ccs_rest}"
    generator="${2:-dynamic-html}"

    specificationFile="api/$specification.yaml"
    resultFolder="result"
    openapiFolder="$resultFolder/${specification}_openapi"

    openapiFile="$openapiFolder/openapi/openapi.yaml"

    mkdir -p "$resultFolder"

    echo "Generating openapi-yaml..."

    generator generate \
        --generator-name "openapi-yaml" \
        --input-spec "$specificationFile" \
        --template-dir api \
        --output "$openapiFolder"

    echo "Generating actual things..."

    generator generate \
        --generator-name "$generator" \
        --input-spec "$openapiFile" \
        --output "${resultFolder}/${specification}_${generator}"
}

if [[ $# -lt 1 ]] || [[ $1 == "all" ]]; then
    specs=(ccs_rest tams_rest)
    gens=(html2 dynamic-html html)

    for spec in "${specs[@]}"; do
        for gen in "${gens[@]}"; do
            if ! generate "$spec" "$gen"; then
                echo "Error while generating spec=$spec gen=$gen" >&2
                exit 1
            fi
        done
    done
elif [[ $1 == "clean" ]]; then
    echo "Cleaning up"
    rm -rf result
else
    generate "$@"
fi
