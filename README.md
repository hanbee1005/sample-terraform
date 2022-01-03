# sample-terraform
Terraform으로 AWS 리소스 생성

## 사전 준비
1. Git 설치
2. SSH 활성화
3. AWS CLI 설치
4. Terraform 설치

## 사용 방법
1. .tf 파일을 작성한다.
2. ```terraform init``` 명령으로 초기화를 진행한다. (1회 수행)
3. ```terraform plan``` 명령으로 작성한 tf 파일의 문법을 확인한다.
4. ```terraform apply``` 명령으로 tf 파일을 실행하여 리소스를 생성한다.
5. AWS Management Console에서 생성된 리소스를 확인한다.