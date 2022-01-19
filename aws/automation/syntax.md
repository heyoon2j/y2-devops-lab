# Systems Manager Document Syntax

## Top-level elements
### ```schemaVersion``` (required)
* 해당 Document Schema Version
</br>

### ```description``` (option)
* 해당 Document에 대한 설명
</br>

### ```parameters``` (option)
* 해당 Document가 허용하는 파마리터 정의.
* 구조는 다음과 같다.
1. ```type``` (required)
    * Parameter Store Parameter 참조 가능 : ```{{ssm:parameter-name}}```
    * https://docs.aws.amazon.com/ko_kr/systems-manager/latest/userguide/sysman-doc-syntax.html#top-level-properties-type
    * ```String``` : ```"abc123"```
    * ```StringList``` : ```["cd ~”, “pwd”]``` (쉼표로 구분)
    * ```Integer``` : ```123``` ("123" 허용 안함)
    * ```Boolean``` : ```true / false``` ("true" 또는 0 허용 안함)
    * ```StringMap``` : ```{"Env”: “Prod”}``` (Key는 문자열만 가능)
    * ```MapList``` : StringMap의 List
2. ```default``` (option)
    * Parameter의 기본값
3. ```description``` (option)
    * Parameter에 대한 설명
4. ```allowedValues``` (option)
    * Parameter에 허용된 값의 배열. 허용되지 않은 값을 입력하면 실행되지 않는다.
    ```
    DirectoryType:
    type: String
    description: "(Required) The directory type to launch."
    default: AwsMad
    allowedValues:
      - AdConnector
      - AwsMad
      - SimpleAd
    ```
5. ```allowedPattern``` (option)
    * Parameter 패턴에 대한 정규 표현식. 허용된 패턴과 일치하지 않으면 실행이 시작되지 않는다.
    ```
    InstanceId:
        type: String
        description: "(Required) The instance ID to target."
        allowedPattern: "^i-[a-z0-9]{8,17}$"
        default: ''
    ```
6. ```displayType``` (option)
    * AWS Management Console를 표시하는 데 사용. textfield는 한 줄 텍스트 상자이고, textarea는 여러 줄 텍스트 상자이다.
    * ```textfield``` 또는 ```textarea```
7. ```minItems``` (option)
    * 허용되는 최소 항목 수
8. ```maxItems``` (option)
    * 허용되는 최대 항목 수
9.  ```minChars``` (option)
    * 허용되는 파라미터 문자 최소 개수
10. ```maxChars``` (option)
    * 허용되는 파라미터 문자 최대 개수
</br>

### ```mainSteps``` (required)
* 여러 Step(플러그인)을 포함할 수 있는 객체
</br>

### ```outputs``` (option)
* 다른 Step에서 사용할 수 있는 데이터
</br>

### ```files``` (option)
*  Document에 첨부되어 Automation 실행 중에 실행되는 스크립트 파일(및 해당 체크섬). ```aws:executeScript`` 작업을 포함하고 하나 이상의 Step에서 첨부 파일이 지정된 Document에서만 적용됩니다.
```
---
files:
  launch.py:
    checksums:
      sha256: 18871b1311b295c43d0f...[truncated]...772da97b67e99d84d342ef4aEXAMPLE

```
</br>




