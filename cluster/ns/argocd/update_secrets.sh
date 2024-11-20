#!/usr/bin/env bash

set -eo pipefail

encryptedClientSecret=$(gopass show -o github.com/organizations/klf2000org/settings/applications/2568443 ClientSecret| \
kubeseal --namespace argocd \
 --controller-namespace sealed-secrets \
 --controller-name sealed-secrets \
 --name argocd-oidc-secret \
 --raw --from-file /dev/stdin)
yq -i e  '.spec.encryptedData.\"oidc.auth0.clientSecret\" |= "'"$encryptedClientSecret"'"' sealedsecret_argocd-oidc-secret.yaml
encryptedClientId=$(gopass show -o github.com/organizations/klf2000org/settings/applications/2568443 ClientId | \
kubeseal --namespace argocd \
 --controller-namespace sealed-secrets \
 --controller-name sealed-secrets \
 --name argocd-oidc-secret \
 --raw --from-file /dev/stdin)
yq -i e  '.spec.encryptedData.\"oidc.auth0.clientId\" |= "'"$encryptedClientId"'"' sealedsecret_argocd-oidc-secret.yaml
git -P diff
git add SealedSecret_argocd-oidc-secret.yaml
git commit -m 'update sealed secrets values'
git push
