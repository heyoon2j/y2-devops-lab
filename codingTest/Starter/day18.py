"""
문자열안에 문자열
"""
import re

def solution(str1, str2):
    pattern = re.compile(str2)
    answer = pattern.findall(str1)

    return 1 if (len(answer) != 0) else 2

solution("ppprrrogrammers", "pppp")

"""
제곱수 판별하기
"""
def solution(n):
    for i in range(1, n+1):
        if i * i == n:
            return 1
    return 2


"""
세균 증식
"""
def solution(n, t):
    answer = 0
    return n*2**t




"""
문자열 정렬하기 (2)
"""
def solution(my_string):
    answer = my_string.lower()
    answer = list(answer)
    answer.sort()
    return ''.join(answer)