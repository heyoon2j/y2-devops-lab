"""
피자는 나눠먹기 (1)
"""
def solution(n):
    if (n % 7) == 0:
        return int(n / 7)
    else:
        return int(n / 7) + 1


"""
피자는 나눠먹기 (2)
"""
def solution(n):
    answer = 1
    while ((6 * answer) % n) != 0:
        answer += 1

    return answer


"""
피자는 나눠먹기 (2)
"""
def solution(slice, n):
    if (n % slice) == 0:
        return n // slice
    else:
        return n // slice + 1




def solution(slice, n):
    return ((n - 1) // slice) + 1

"""
배열의 평균값
"""
def solution(numbers):
    answer = 0

    for i in numbers:
        answer += i    
    return answer / len(numbers)
 


