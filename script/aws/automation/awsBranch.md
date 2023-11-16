# aws:branch
</br>

## 연산자 사용
### And 연산자
```
mainSteps:
- name: switch2
  action: aws:branch
  inputs:
    Choices:
    - And:
      - Variable: "{{GetInstance.pingStatus}}"
        StringEquals: running
      - Variable: "{{GetInstance.platform}}"
        StringEquals: Windows
      NextStep: runPowerShellCommand
    - And:
      - Variable: "{{GetInstance.pingStatus}}"
        StringEquals: running
      - Variable: "{{GetInstance.platform}}"
        StringEquals: Linux
      NextStep: runShellCommand
    Default:
      sleep3
```
</br>

### Or 연산자
```
- Or:
  - Variable: "{{parameter1}}"
    StringEquals: Windows
  - Variable: "{{BooleanParam1}}"
    BooleanEquals: true
  NextStep: RunPowershellCommand
  
- Or:
  - Variable: "{{parameter2}}"
    StringEquals: Linux
  - Variable: "{{BooleanParam2}}"
    BooleanEquals: true
  NextStep: RunShellScript

```
</br>

### Not 연산자
```
mainSteps:
- name: switch
  action: aws:branch
  inputs:
    Choices:
    - NextStep: sleep2
      Not:
        Variable: "{{testParam}}"
        StringEquals: Linux
    - NextStep: sleep1
      Variable: "{{testParam}}"
      StringEquals: Windows
    Default:
      sleep3
```
</br>

### Operation 종류
1. String operations
  * StringEquals
  * EqualsIgnoreCase
  * StartsWith
  * EndsWith
  * Contains
2. Numeric operations
  * NumericEquals
  * NumericGreater
  * NumericLesser
  * NumericGreaterOrEquals
  * NumericLesser
  * NumericLesserOrEquals
3. Boolean operation
  * BooleanEquals
</br>
</br>


## 옵션 사용
* ```onFailure```: 이 옵션은 실패 시 자동화가 중지되어야 하는지, 계속되어야 하는지 또는 다른 단계로 이동해야 하는지를 나타냅니다. 이 옵션의 기본값은 ```Abort``` 이다.
* ```nextStep```: 이 옵션은 한 단계를 성공적으로 완료한 후 처리할 자동화의 단계를 지정합니다.
* ```isEnd```: 이 옵션은 특정 단계 종료 시 자동화를 중지합니다. 이 옵션의 기본값은 false입니다.
* ```isCritical```: 이 옵션은 자동화의 성공적 완료에 대해 단계를 심각으로 지정합니다. 이 지정이 있는 단계가 실패하면 Automation은 자동화의 최종 상태를 Failed로 보고합니다. 이 옵션의 기본값은 true입니다.
</br>

### onFail
* ```onFailure: Abort```: 실패시, 자동화 중지
* ```onFailure: step:step_name```: "step_name" 단계로 이동
```
---
schemaVersion: '0.3'
description: Install MSI package and run validation.
assumeRole: "{{automationAssumeRole}}"
parameters:
  automationAssumeRole:
    type: String
    description: "(Required) Assume role."
  packageName:
    type: String
    description: "(Required) MSI package to be installed."
  instanceIds:
    type: String
    description: "(Required) Comma separated list of instances."
mainSteps:
- name: InstallMsiPackage
  action: aws:runCommand
  maxAttempts: 2
  onFailure: Abort
  inputs:
    InstanceIds:
    - "{{instanceIds}}"
    DocumentName: AWS-RunPowerShellScript
    Parameters:
      commands:
      - msiexec /i {{packageName}}
- name: TestInstall
  action: aws:invokeLambdaFunction
  maxAttempts: 1
  timeoutSeconds: 500
  inputs:
    FunctionName: TestLambdaFunction
...
```
</br>

### nextStep / isEnd
* ```nextStep: step_name```: "step_name" 단계로 이동
* ```isEnd: true``` : 자동화 중지 (true, false)
```
mainSteps
- name: InstallMsiPackage
  action: aws:runCommand
  onFailure: step:PostFailure
  maxAttempts: 2
  inputs:
    InstanceIds:
    - "{{instanceIds}}"
    DocumentName: AWS-RunPowerShellScript
    Parameters:
      commands:
      - msiexec /i {{packageName}}
  nextStep: TestInstall
- name: TestInstall
  action: aws:invokeLambdaFunction
  maxAttempts: 1
  timeoutSeconds: 500
  inputs:
    FunctionName: TestLambdaFunction
  isEnd: true
- name: PostFailure
  action: aws:invokeLambdaFunction
  maxAttempts: 1
  timeoutSeconds: 500
  inputs:
    FunctionName: PostFailureRecoveryLambdaFunction
  isEnd: true
...
```
</br>

### isCritical
* ```isCritical: true```: 해당 단계를 중요 단계로 정의함으로써 ```onFailure: step:stepName```으로 실패시 넘어가 단계를 통과하더라도 실패로 처리한다.
```
---
name: InstallMsiPackage
action: aws:runCommand
onFailure: step:VerifyDependencies
isCritical: false
maxAttempts: 2
inputs:
  InstanceIds:
  - "{{instanceIds}}"
  DocumentName: AWS-RunPowerShellScript
  Parameters:
    commands:
    - msiexec /i {{packageName}}
nextStep: TestPackage
...
```


