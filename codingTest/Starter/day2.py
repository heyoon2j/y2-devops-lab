def solution(denum1, num1, denum2, num2):
    answer = [0, 0]
    denum = denum1*num2 + denum2*num1
    num = num1*num2
    x = 1

    if denum >= num:
        for i in range(num, 1,-1):
            print(i)
            if ((denum % i) == 0) and ((num % i) == 0):
                x = i
                break
    else:
        for i in range(denum, 1,-1):
            if ((denum % i) == 0) and ((num % i) == 0):
                x = i
                break

    answer[0] = denum // x
    answer[1] = num // x

    return answer

print(solution(1,2,3,4))


"""
배열 두배 만들기
"""
"""
def solution(numbers):
    answer = []
    for i in range(len(numbers)):
        answer.append(2 * numbers[i])
    return answer

numbers = [1, 2, 3, 4, 5]
print(solution(numbers))
"""