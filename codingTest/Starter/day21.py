"""
숨어있는 숫자의 덧셈 (2)
"""
import re

def solution(my_string):
    pattern = re.compile("[0-9]+")
    answer = re.findall(pattern, my_string)
    sum = 0

    for i in answer:
        sum += int(i)

    return sum

solution("aAb1B2cC34oOp")

"""
안전지대
"""
def checkBoom(board, i, j):
    checkList = [(-1,-1), (0,-1), (1,-1), (-1,0), (1,0), (-1,1), (0,1), (1,1)]
    size = len(board)

    for check in checkList:
        x = check[0] + i
        y = check[1] + j
        if x < size and x >= 0 and y >=0 and y < size and board[y][x] != 1:
            board[y][x] = 2


def solution(board):
    answer = 0
    size = len(board)

    for y in range(size):
        for x in range(size):
            if board[y][x] == 1:
                checkBoom(board, x, y)

    for i in board:
        answer += i.count(0)

    return answer

solution([[1,0,0],[0,0,0],[0,0,0]])

"""
삼각형의 완성조건 (2)
"""
def solution(sides):
    a = min(sides)
    b = max(sides)

    return 2 * a - 1


"""
외계어 사전
"""
def solution(spell, dic):
    for word in dic:
        count = 0
        for alpb in spell: 
            if word.count(alpb) != 0:
                count += 1
        if count == len(spell):
            return 1
    return 2


solution(["p", "o", "s"], ["sod", "eocd", "qixm", "adio", "soo"])
