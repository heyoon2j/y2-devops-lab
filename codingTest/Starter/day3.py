"""
나머지 구하기
"""

def solution(num1, num2):
    return num1 % num2

print(solution(-3,2))


"""
중앙값 구하기

1) array 계산

2) list 계산

2) 라이브러리 활용
"""
def solution(array):
    size = len(array)
    """
    for i in range(len(array)):
        k = i
        for j in range(i+1, len(array)):
            if array[j] < array[k]:
                k = j
        temp = array[i]
        array[i] = array[k]
        array[k] = temp
    return array[size//2]
    """
    
    array.sort()
    return array

print(solution([9, -1, 0]))

"""
최빈값 구하기
"""
def solution(array):
    answer = 0
    countMap = dict()
    cKey = []

    for i in range(len(array)):
        if array[i] in countMap:
            countMap[array[i]] += 1
        else:
            countMap[array[i]] = 1

    cKey = list(countMap.keys())
    print(countMap, cKey)
    
    if len(cKey) == 1:
        return array[0]

    # else
    answer = cKey[0]
    check = False

    for i in range(1, len(cKey)):
        if countMap[cKey[i]] == countMap[answer]:
            check = True
        if countMap[cKey[i]] > countMap[answer]:
            check = False
            answer = cKey[i]

    if check == True:
        return -1

    else:
        return answer

print(solution([1]))


"""
짝수는 싫어요
"""

def solution(n):
    answer = []

    for i in range(1, n+1):
        if (i % 2) != 0:
            answer.append(i)
    return answer

print(solution(15))

