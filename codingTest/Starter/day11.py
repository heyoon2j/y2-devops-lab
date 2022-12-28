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
            print(i)
        else:
            nList.append(i)
    print("===========")
    return answer


print(solution(15))


"""
최댓값 만들기(1)
"""
def solution(numbers):
    answer = 4
    print(answer)
    answer = 2
    a = 3
    print (answer + a)
    return answer



"""
팩토리얼
"""
