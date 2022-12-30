"""
모음 제거
"""
def solution(my_string):
    a = ['a', 'e', 'i', 'o', 'u']
    for i in a:
        my_string = my_string.replace(i, '')
    return my_string

print(solution("bus"))


"""
문자열 정렬하기 (1)
"""
def solution(my_string):
    answer = []
    for i in my_string:
        if i in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']:
            answer.append(int(i))
    
    answer.sort()
    
    return answer


"""
숨어있는 숫자의 덧셈 (1)
"""
import re

def solution(my_string):
    answer = 0
    pattern = re.compile("[0-9]")
    numbers = pattern.findall(my_string)
    for i in numbers:
        answer += int(i)
    return answer

solution("aAb1B2cC34oOp")


"""
소인수분해
"""
def solution(n):
    answer = []
    
    for i in range(2, n+1):
        if n == 1:
            break

        if (n % i) == 0:
            answer.append(i)
        while (n % i) == 0:
            n = int(n / i)

    return answer

