"""
옷가게 할인 받기
"""
def solution(price):
    if price >= 500000:
        return int(price * 0.8)
    elif price >= 300000:
        return int(price * 0.9)
    elif price >= 100000:
        return int(price * 0.95)
    else:
        return price


"""
아이스 아메리카노
"""
def solution(money):
    americano = 5500
    answer = [int(money/americano), money%americano]
    return answer



"""
나이 출력
"""
def solution(age):
    answer = 0
    standard = 2022
    return standard - age + 1




"""
배열 뒤집기
"""
def solution(num_list):
    
    answer = num_list
    #answer.reverse()

    size = len(num_list)
    for i in range(size//2):
        temp = num_list[i]
        num_list[i] = num_list[size-i-1]
        num_list[size-i-1] = temp


    return answer


num_list = [1, 0, 1, 1, 1, 3, 5]
print(solution(num_list))
print(num_list)
