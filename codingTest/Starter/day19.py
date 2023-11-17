"""
7의 개수
"""
def solution(array):
    answer = 0
    for i in array:
        while (i % 10) != 0:
            if (i % 10) == 7:
                answer += 1
            i = int(i / 10)
    return answer

print(solution([7, 77, 17]))

"""
잘라서 배열로 저장하기
"""
def solution(my_str, n):
    answer = []
    size = []
    my_str = list(my_str)
    i = len(my_str)
    while i > 0:
        if i >= n:
            size.append(n)
        else:
            size.append(i)
        i -= n

    for i in size:
        word = ''
        for j in range(size.pop(0)):
            word += my_str.pop(0)
        
    return answer


"""
중복된 숫자 개수
"""
def solution(array, n):
    return array.count(n)


"""
머쓱이보다 키 큰 사람
"""
def solution(array, height):
    idx = len(array)
    array.sort()
    for i in range(len(array)):
        if array[i] > height:
            idx = i
            break;
    return len(array) - idx


