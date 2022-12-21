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
    count = dict()
    cList = []

    if len(array) == 1:
        return 1

    for i in range(len(array)):
        if array[i] in count:
            count[array[i]] += 1
        else:
            count[array[i]] = 1

    cList = list(count.values())
    cList.sort(reverse=True)
    
    if cList[0] == cList[1]:
        return -1

    else:
        return cList[0]

print(solution([1, 2, 3, 3, 3, 4]))


"""
"""



"""
"""




