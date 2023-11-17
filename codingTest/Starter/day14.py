"""
가까운 수
"""
def solution(array, n):
    answer = 0

    array.sort()
    minValue = abs(n- array[0])
    for i in range(len(array)):
        if abs(n - array[i]) < minValue:
            answer = i
            minValue = abs(n - array[i])

    return array[answer]


print(solution([3, 10, 28], 20))


"""
369게임
"""
import re

def solution(order):
    orderStr = str(order)
    pattern = re.compile("(3|6|9)")
    answer = pattern.findall(orderStr)
    return len(answer)


"""
암호 해독
"""
def solution(cipher, code):
    answer = ''
    for i in range(code - 1, len(cipher), code):
        answer += cipher[i]

    return answer




"""
대문자와 소문자
"""
def solution(my_string):
    answer = ''

    for i in my_string:
        ch = ord(i)
        if ch < 97:
            answer += chr(ch + 32)
        else:
            answer += chr(ch - 32)
    return answer

print(solution("cccCCC"))
