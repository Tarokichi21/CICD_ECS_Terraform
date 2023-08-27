### CI/CD for Amazon ECS(RollingUpdate)

ECSへの自動ローリングアップデートデプロイプラットフォームを構築するTerraformのコードです

参考サイト

[①TerraformでECS ローリング更新のCodePipelineを作ってみた](https://dev.classmethod.jp/articles/terraform-ecs-rolling-update-codepipeline/)

[②TerraformでCodePipeline + CodeCommit作る際にトリガーでちょっとハマった話](https://dev.classmethod.jp/articles/terraform-codepipeline-codecommit-trigger/)

[③AWS CI/CD for Amazon ECSハンズオン](https://pages.awscloud.com/rs/112-TZM-766/images/AWS_CICD_ECS_Handson.pdf)


### .tfstate用s３作成
```
aws s3 mb s3://cicd-ecs0001
```

### Terraform基本コマンド
```
cd env
terraform init
terraform plan
terraform apply
terraform output
```

### RemoteSSHでEC2からDockerImageをpushする場合の環境構築
```
sudo su
yum update -y
yum install -y docker && yum install -y httpd && yum install git
systemctl start docker && systemctl start httpd
```
### AWS　CLI設定
```
aws configure
```

### DockerImageをECRにPushする手順
```
cd ../../
docker build -t cicd-ecs-dev-ecr-repository .
docker images
aws ecr get-login-password | docker login --username AWS --password-stdin https://<aws_account_id>.dkr.ecr.<region>.amazonaws.com
docker tag cicd-ecs-dev-ecr-repository:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/cicd-ecs-dev-ecr-repository:latest
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/cicd-ecs-dev-ecr-repository:latest
```

### CodeCommitへのpush
### AWS CodeCommit の HTTPS Git 認証情報を事前に生成しておく必要があります
```
cd sample
git init
git remote add origin https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/cicd-ecs-dev-repository
git add .
git commit -m "initial commit"
git push origin master
```

### (補足)コンフリクトが起きたら以下コマンドを実施する
```
git config pull.rebase true
```

