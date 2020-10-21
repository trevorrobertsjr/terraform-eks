https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/tls_certificate#example-usage
https://marcincuber.medium.com/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c
https://stackoverflow.com/questions/58507993/eks-iam-roles-for-services-account-not-working/58519269#58519269


aws eks describe-cluster --name training-eks-PvBU7905 --query "cluster.identity.oidc.issuer" --output text

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

export OIDC_PROVIDER=$(aws eks describe-cluster --name training-eks-PvBU7905 --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")


kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: testiam
EOF

read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:default:testiam"
        }
      }
    }
  ]
}
EOF
echo "${TRUST_RELATIONSHIP}" > trust.json

aws iam create-role --role-name k8ssatestiamrole --assume-role-policy-document file://trust.json --description "IAM role for K8s SA"

aws iam attach-role-policy --role-name k8ssatestiamrole --policy-arn=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

apiVersion: v1
kind: Pod
metadata:
  name: podiam
spec:
  serviceAccountName: testiam
  containers:
  - image: amazonlinux

kubectl run podiam --serviceaccount='testiam' --rm -i --tty --image amazonlinux -- bash
kubectl run nopodiam --rm -i --tty --image amazonlinux -- bash
kubectl run podiam2 --serviceaccount='testiam' --rm -i --tty --image amazonlinux -- bash


apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456765097:role/k8ssatestiamrole

kubectl annotate serviceaccount testiam eks.amazonaws.com/role-arn=arn:aws:iam::5123456765097:role/k8ssatestiamrole