"""
배열 자르기
"""
def solution(numbers, num1, num2):
    answer = numbers[num1:num2+1]

    answer = numbers
    for i in range(len(numbers)-num2-1):
        answer.pop(len(numbers)-1)
        
    for i in range(num1):
        answer.pop(0)
        
    return answer


"""
외계행성의 나이
"""
def solution(age):
    age962 = {0:'a', 1:'b', 2:'c', 3:'d', 4:'e', 5:'f', 6:'g', 7:'h', 8:'i', 9:'j'}

    if age == 0:
        return 'a'

    answer = []
    print(len(answer))
    # else
    while age != 0:
        answer.insert(0, age962[age%10])
        age //= 10
    
    return ''.join(answer)

print(solution(10))

"""
진료 순서 정하기
"""
def solution(emergency):
    answer = [0]*len(emergency)
    emgMap = {}
    for i in range(len(emergency)):
        emgMap[emergency[i]] = i
    emergency.sort(reverse=True)
    print(emergency)


    for i in range(len(emergency)):
        answer[emgMap[emergency[i]]] = i + 1
    return answer
print(solution(	[30, 10, 23, 6, 100]))



"""
순서쌍의 개수
"""
def solution(n):
    answer = 0

    for i in range(n):
        
    return answer



