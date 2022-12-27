# Day 10
"""
점의 위치 구하기
"""
def solution(dot):
    answer = 0
    x = dot[0]
    y = dot[1]
    
    if x > 0 and y >0:
        return 1
    elif x < 0 and y >0:
        return 2
    elif x < 0 and y <0:
        return 3
    else:
        return 4


"""
2차원으로 만들기
"""
def solution(num_list, n):
    answer = []

    for i in range(int(len(num_list)/n)):
        answer.append(num_list[i*n:(i+1)*n])
    return answer

print(solution([1, 2, 3, 4, 5, 6, 7, 8],2))




"""
공 던지기
"""
def solution(numbers, k):
    answer = 0
    size = len(numbers)
    idx = (2*k - 1) % size
    return numbers[idx - 1]

print(solution([1, 2, 3, 4, 5, 6],3))



"""
배열 회전시키기
"""
def solution(numbers, direction):
    answer = []
    if direction == "left":
        numbers.insert(len(numbers), numbers.pop(0))
    else:
        numbers.insert(0, numbers.pop(len(numbers)))
    return numbers



