# Systems Manager Document Syntax

## Top-level elements
### ```schemaVersion```
* 해당 Document Schema Version
</br>

### ```description```
* 해당 Document에 대한 설명
</br>

### ```parameters```
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
    * 
5. https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-doc-syntax.html
6. 
* `````` : 
* `````` : 
* `````` : 
* `````` : 
* `````` : 










