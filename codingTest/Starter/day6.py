# Day 6

"""
문자열 뒤집기
"""
def solution(my_string):
    answer = ''
    answer = my_string
    answer = ''.join(reversed(my_string))

    answer = list(answer)
    size = len(answer)
    for i in range(size):
        temp = answer[i]
        answer[i] = answer[size-i-1]
        answer[size-i-1] = temp

    return answer


"""
직각삼각형 출력하기
"""
n = int(input())
for i in range(n):
    for j in range(i+1):
        print("*", end='')
    print("")


"""
짝수 홀수 개수
"""
def solution(num_list):
    a, b = 0, 0
    for i in num_list:
        if (i % 2) == 0:
            a += 1
        else:
            b += 1

    return [a, b]



"""
문자 반복 출력하기
"""
def solution(my_string, n):
    answer = ''
    for i in my_string:
        answer += (i*n)
    return answer

print(solution("hello",2))





