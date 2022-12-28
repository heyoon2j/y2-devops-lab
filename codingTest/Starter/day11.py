"""
주사위의 개수
"""
def solution(box, n):
    return (box[0]//n)*(box[1]//n)*(box[2]//n)


"""
합성수 찾기
"""
def chkdiv(n, nList):
    for i in nList:
        if (n % i) == 0:
            return True

    return False


def solution(n):
    answer = 0
    nList = [2, 3]

    for i in range(4, n+1):
        if chkdiv(i, nList) == True:
            answer += 1
        else:
            nList.append(i)
    return answer

print(solution(15))


"""
최댓값 만들기(1)
"""
def solution(numbers):
    numbers.sort(reverse=True)
    return numbers[0]*numbers[1]



"""
팩토리얼
"""

def solution(n):
    answer = 1

    if n == 1:
        return 1

    while True:
        val = 1
        for i in range(1, answer + 1):
            val *= i
        
        if val > n:
            return answer - 1
        else:
            answer += 1

print(solution(3628800))