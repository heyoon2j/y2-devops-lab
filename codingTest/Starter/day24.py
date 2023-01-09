"""
치킨 쿠폰
"""
def solution(chicken):
    answer = 0

    if chicken == 0:
        return 0

    while (chicken//10) != 0:
        answer += chicken//10
        chicken = chicken//10 + (chicken%10)
    
    return answer



"""
이진수 더하기
"""
def solution(bin1, bin2):
    bin1 = '0b' + bin1
    bin2 = '0b' + bin2
    answer = int(bin1, 2) + int(bin2, 2)
    answer = str(bin(answer)).replace('0b', '')
    return answer


solution("10", "11")

"""
A로 B 만들기
"""
def solution(before, after):
    before = list(before)
    after = list(after)

    before.sort()
    after.sort()

    for i in range(len(before)):
        if before[i] != after[i]:
            return 0
    return 1

solution("olleh", "hello")


"""
k의 개수
"""
def solution(i, j, k):
    answer = 0
    
    for n in range(i,j+1):
        nStr = str(n)
        answer += nStr.count(str(k))

    return answer
solution(1,13,1)