#!/usr/bin/env bash
function ku-apply(){
    export scope=${1:-undefined}
    exit_code=1
    cnt=0
    until [[ $exit_code -eq 0 || $cnt -gt 5 ]]; do
        ((cnt++))
        kustomize build --enable-helm . \
        | yq '(select(.kind == strenv(scope) ))'\
        | kubectl apply --force=true --wait=true  -f -
        exit_code=$?
    done
}
cd sealed-secrets
rm -rf helm-charts

ku-apply CustomResourceDefinition

exit_code=1
until [[ $exit_code -eq 0 ]]; do
    kustomize build --enable-helm . |kubectl apply --force=true --wait=true  -l app=sealed-secrets -f -
    exit_code=$?
done

kubectl -n sealed-secrets wait --for=condition=Available=true deployment/sealed-secrets

rm -rf helm-charts/
cd ../argocd
rm -rf helm-charts/
bash -c ./update_secrets.sh

exit_code=1
until [[ $exit_code -eq 0 ]]; do
    kustomize build --enable-helm . |kubectl apply --force=true --wait=true -f -
    exit_code=$?
done

kubectl -n argocd wait --for=condition=Available deployment/argocd-applicationset-controller
kubectl -n argocd wait --for=condition=Available deployment/argocd-server
kubectl -n argocd wait --for=condition=Available deployment/argocd-repo-server
kubectl -n argocd wait --for=condition=Available deployment/argocd-redis
kubectl -n argocd wait -l statefulset.kubernetes.io/pod-name=argocd-application-controller-0 --for=condition=ready pod --timeout=-1s

sleep 10

# kubectl rollout restart deployment/argocd-server -n argocd
# kubectl rollout restart  statefulset/argocd-application-controller -n argocd
# sleep 5
argocd login --core
kubectl config set-context --current --namespace=argocd
argocd app list
argocd app get argocd/root-argocd-app --hard-refresh
argocd app wait root-argocd-app --sync --health
# argocd app sync argocd --kube-context argocd --server-side --apply-out-of-sync-only --timeout 50
# argocd app sync argocd --kube-context argocd --resource bitnami.com:SealedSecret:argocd-oidc-secret

# kubectl rollout restart deployment/sealed-secrets -n sealed-secrets
# kubectl rollout restart deployment/argocd-dex-server -n argocd
# kubectl rollout restart deployment/argocd-redis -n argocd
