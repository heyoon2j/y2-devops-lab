"""
문자열 밀기
"""
def solution(A, B):
    answer = 0
    for i in range(len(A)):
        print(A[len(A)-i:] + A[0:len(A)-i])
        if (A[len(A)-i:] + A[0:len(A)-i]) == B:
            return answer
        answer += 1
    return -1

solution("apple", "elppa")


"""
종이 자르기
"""
def solution(M, N):
    a = max(M, N)
    b = min(M, N)
    return (a-1)*b + (b-1)


"""
연속된 수의 합
"""
def solution(num, total):
    answer = []
    n = int((total - int((num-1)*num/2))/num)
    print(n)
    for i in range(n, n+num):
        answer.append(i)
    return answer

solution(3, 12)





"""
다음에 올 숫자
"""
def solution(common):
    a = common[1] - common[0]
    size = len(common)

    if a == common[2] - common[1]:
        return common[0] + a * size
    else:
        a = common[2]//common[1]
        print(a**(size-1))
        return common[0]*(a**size)

solution([2,4,8])
