"""
편지
"""
def solution(message):
    return len(message)*2


"""
가장 큰 수 찾기
"""
def solution(array):
    return [max(array), array.index(max(array))]


"""
문자열 계산기
"""
def solution(my_string):
    sList = my_string.split(" ")
    answer = int(sList[0])

    for i in range(1, len(sList), 2):
        if sList[i] == "+":
            answer += int(sList[i+1])
        else:
            answer -= int(sList[i+1])
    return answer

print(solution("100 + 500"))

"""

"""