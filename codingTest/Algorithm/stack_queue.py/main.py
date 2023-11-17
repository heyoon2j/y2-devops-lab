"""
같은 숫자는 실어
"""
def solution(arr):
    answer = []
    answer.append(arr[0])
    for i in range(1, len(arr)):
        if arr[i-1] != arr[i]:
            answer.append(arr[i])
    return answer

solution([1,1,3,3,0,1,1])


"""
올바른 괄호
"""
from collections import deque

def solution(s):
    deq = deque()

    for i in range(len(s)):
        if len(deq) == 0:
            deq.append(s[i])
            continue

        val = deq.pop()
        if val == "(" and s[i] == ")":
            pass
        else:
            deq.append(val)
            deq.append(s[i])

    if len(deq) == 0:
        return True
    else:
        return False

solution("(())()")