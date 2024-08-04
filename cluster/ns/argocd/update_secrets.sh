#!/usr/bin/env bash

set -eo pipefail

encryptedClientSecret=$(gopass show -o github.com/organizations/klf2000org/settings/applications/2568443 ClientSecret| \
kubeseal --namespace argocd \
 --controller-namespace sealed-secrets \
 --controller-name sealed-secrets \
 --name argocd-oidc-secret \
 --raw --from-file /dev/stdin)
yq -i e  '.oidc.oauth.encryptedClientSecret |= "'"$encryptedClientSecret"'"' values_my-argocd-secrets.yaml
encryptedClientId=$(gopass show -o github.com/organizations/klf2000org/settings/applications/2568443 ClientId | \
kubeseal --namespace argocd \
 --controller-namespace sealed-secrets \
 --controller-name sealed-secrets \
 --name argocd-oidc-secret \
 --raw --from-file /dev/stdin)
yq -i e  '.oidc.oauth.encryptedClientId |= "'"$encryptedClientId"'"' values_my-argocd-secrets.yaml 

git add values_my-argocd-secrets.yaml
git commit -m 'update sealed secrets'
git push