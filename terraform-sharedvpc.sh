#!/bin/bash  

apk --no-cache add jq
# apk add --update --no-cache python3 && ln -sf python3

CWD="$(pwd)"
echo $CWD
PLAN=plan.tfplan


echo "Shared VPC"
tf_state="${ENV}_${REGION}_sharedvpc"
echo "TF_STATE Name : ${tf_state}"


chdir $CWD/platform/connectivity/sharedvpc
echo "Change directory : $(pwd)"

terraform init -backend-config=address=${TF_ADDRESS}/${tf_state} \
                -backend-config=lock_address=${TF_ADDRESS}/${tf_state}/lock \
                -backend-config=unlock_address=${TF_ADDRESS}/${tf_state}/lock \
                -backend-config=username=${TF_USERNAME} \
                -backend-config=password=${TF_PASSWORD} \
                -backend-config=lock_method=POST \
                -backend-config=unlock_method=DELETE \
                -backend-config=retry_wait_min=5 \
                -upgrade \
                -reconfigure

                # -backend-config="skip_cert_verification=true" \

# terraform  plan --out=${PLAN} \
#      -var-file="$CWD/config/${ENV}_${REGION}_sharedvpc.tfvars.json" 

# terraform   show \
#     --json ${PLAN} | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > ${JSON_PLAN_FILE}

echo " Apply changes"
TF_HUB_STATE="${ENV}_${REGION}_hub"

terraform   apply -var-file="$CWD/config/${ENV}_${REGION}_sharedvpc.tfvars.json"  \
    -var "TF_ADDRESS=${TF_ADDRESS}" \
    -var "TF_HUB_STATE=${TF_HUB_STATE}" \
    -var "TF_USERNAME=${TF_USERNAME}" \
    -var "TF_PASSWORD=${TF_PASSWORD}" \
    -auto-approve

