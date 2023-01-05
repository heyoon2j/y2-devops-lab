"""
저주의 숫자 3
"""
def solution(n):
    answer = 0
    for i in range(1,n+1):
        answer += 1

        while answer % 3 == 0 or "3" in str(answer):
            answer += 1
            
    return answer

solution(15)

"""
평행
"""
def solution(dots):
    dots.sort()
    if (dots[0][1] - dots[1][1]) / (dots[0][0] - dots[1][0]) == (dots[2][1] - dots[3][1]) / (dots[2][0] - dots[3][0]):
        return 1

    dots.sort(key = lambda x : (x[1], x[0]))
    if (dots[0][1] - dots[1][1] / dots[0][0] - dots[1][0]) == (dots[2][1] - dots[3][1] / dots[2][0] - dots[3][0]):
        return 1

    return 0

solution([[1, 4], [9, 2], [3, 8], [11, 6]])


"""
겹치는 선분의 길이
"""
def solution(lines):
    answer = 0
    lineList = []

    for line in lines:
        for i in range(line[0], line[1]):
            if lineList.count((i, i+1)) == 1:
                answer += 1
            lineList.append((i, i+1))
            
    return answer

solution([[0, 1], [2, 5], [3, 9]])


"""
유한소수 판별하기
"""
def solution(a, b):
    for i in range(min(a,b), 1, -1):
        if (a % i == 0) and (b % i == 0):
            a //= i
            b //= i

    while b % 2 == 0:
        b /= 2
    while b % 5 == 0:
        b /= 5
    
    if b == 1:
        return 1
    else:
        return 2
