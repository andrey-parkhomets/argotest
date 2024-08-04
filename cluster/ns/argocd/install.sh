#!/usr/bin/env bash
set -x
exit_code=1
until [[ $exit_code -eq 0 ]]; do 
kubectl kustomize --enable-helm|kubectl apply -f -
exit_code=$?
done
kubectl -n sealed-secrets wait --for=condition=Available=true deployment/sealed-secrets
bash -c ./update_secrets.sh
sleep 20
kubectl rollout restart deployment/argocd-dex-server -n argocd
kubectl rollout restart deployment/argocd-repo-server -n  argocd
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout restart deployment/argocd-applicationset-controller -n argocd
sleep 20
kubectl -n argocd wait --for=condition=Available deployment/argocd-dex-server
kubectl -n argocd wait --for=condition=Available deployment/argocd-server