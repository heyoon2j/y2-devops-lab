"""
영어가 싫어요
"""
def solution(numbers):
    nMap = {0:"zero", 1:"one", 2:"two", 3:"three", 4:"four", 5:"five", 6:"six", 7:"seven", 8:"eight", 9:"nine"}

    for i in range(10):
        numbers = numbers.replace(nMap[i], str(i))

    return int(numbers)

print(solution("onetwothreefourfivesixseveneightnine"))

"""
인덱스 바꾸기
"""
def solution(my_string, num1, num2):
    temp = my_string[num2]
    my_string[num2] = my_string[num1]
    my_string[num1] = temp

    return my_string


"""
한 번만 등장한 문자
"""
def solution(s):
    answer = ''
    sList = list(s)
    sList.sort()
    
    for i in sList:
        if sList.count(i) == 1:
            answer += i
    
    return answer

"""
약수 구하기
"""
def solution(n):
    answer = []
    for i in range(1,n+1):
        if (n % i) == 0:
            answer.append(i)
    return answer
