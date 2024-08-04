#!/usr/bin/env bash
rm -rf helm-charts/argo-cd-*.tgz helm-charts/sealed-secrets-*.tgz
exit_code=1
until [[ $exit_code -eq 0 ]]; do 
kustomize build --enable-helm . |kubectl apply --force=true -l app==sealedsecret -f -
exit_code=$?
done
kubectl -n sealed-secrets wait --for=condition=Available=true deployment/sealed-secrets
bash -c ./update_secrets.sh
until [[ $exit_code -eq 0 ]]; do 
kustomize build --enable-helm . |kubectl apply --force=true -l app!=sealedsecret -f -
exit_code=$?
kubectl -n argocd wait --for=condition=Available deployment/argocd-applicationset-controller
kubectl -n argocd wait --for=condition=Available deployment/argocd-server
kubectl -n argocd wait --for=condition=Available deployment/argocd-repo-server
kubectl -n argocd wait --for=condition=Available deployment/argocd-redis
sleep 10
argocd login --core
argocd app sync argocd --kube-context argocd --force --prune --replace
sleep 10
kubectl rollout restart deployment/sealed-secrets -n sealed-secrets
kubectl rollout restart deployment/argocd-dex-server -n argocd
kubectl rollout restart deployment/argocd-redis -n argocd
sleep 5
kubectl rollout restart deployment/argocd-applicationset-controller -n argocd

