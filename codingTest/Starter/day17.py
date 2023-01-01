"""
숫자 찾기
"""
def solution(num, k):
    nStr = str(num)
    if str(k) in nStr:
        return nStr.index(str(k)) + 1
    else:
        return -1



"""
n의 배수 고르기
"""
def solution(n, numlist):
    answer = []
    for i in numlist:
        if i % n == 0:
            answer.append(i)
    return answer


"""
자릿수 더하기
"""
def solution(n):
    answer = 0
    for i in str(n):
        answer += int(i)
    return answer


"""
OX퀴즈
"""
def solution(quiz):
    answer = []

    for cal in quiz:
        cal = cal.split()
        result = 0
        if cal[1] == "+":
            result = int(cal[0]) + int(cal[2])
        else:
            result = int(cal[0]) - int(cal[2])
        
        if result == int(cal[4]):
            answer.append("O")
        else:
            answer.append("X")

    return answer