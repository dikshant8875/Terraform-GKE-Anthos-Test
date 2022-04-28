#!/usr/bin

gcloud container clusters get-credentials tf-gke-pvt-cluster --zone us-central1-c --project dikshantnew

kubectl get nodes

curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.13 > asmcli

chmod +x asmcli

./asmcli install --project_id "dikshantnew" --cluster_name "tf-gke-pvt-cluster" --cluster_location "us-central1-c" --output_dir asm --enable_all --ca mesh_ca



kubectl label namespace default  istio-injection=enabled istio.io/rev=asm-1132-2 --overwrite


kubectl apply -f ./myapp/deployment.yaml

kubectl apply -f ./myapp/service.yaml
