"""
특정 문자 제거하기
"""
def solution(my_string, letter):
    """
    answer = my_string.replace(letter, '')
    return answer
    """
    answer = list(my_string)
    for i in range(len(answer)):
        if answer[i] == letter:
            answer[i] = ""
    return ''.join(answer)           

print(solution("BCBdbe", "B"))

"""
각도기
"""
def solution(angle):

    for i in range(2):
        if (angle > 90*i) and (angle < 90*(i+1)):
            return (i*2) + 1
        if angle == 90*(i+1):
            return (i*2) + 2

print(solution(91))



"""
양꼬치
"""
def solution(n, k):
    answer = n*12000 + k*2000 - (n//10)*2000
    return answer


"""
짝수의 합
"""
def solution(n):
    answer = 0
    """
    for i in range(1, n+1):
        if (i % 2) == 0:
            answer += i
    return answer
    """
    return (1 + (n // 2)) * (n // 2) 
print(solution(10))