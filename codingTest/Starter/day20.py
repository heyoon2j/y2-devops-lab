"""
직사각형 넓이 구하기
"""
def solution(dots):
    answer = []
    for i in range(1,4):
        answer.append(((dots[0][0] - dots[i][0])**2 + (dots[0][1] - dots[i][1])**2)**0.5)
    answer.remove(max(answer))
        
    return answer[0] * answer[1]


"""
캐릭터의 좌표
"""
def solution(keyinput, board):
    answer = [0, 0]

    action = {"left":(-1,0), "right":(1,0), "up":(0,1), "down":(0,-1)}
    maxX = int(board[0]//2)
    maxY = int(board[1]//2)

    for key in keyinput:
        if abs(answer[0] + action[key][0]) <= maxX and abs(answer[1] + action[key][1]) <= maxY:
            answer[0] += action[key][0]
            answer[1] += action[key][1]

    return answer

solution(["down", "down", "down", "down", "down"],[1,1])



"""
최댓값 만들기 (2)
"""
def solution(numbers):
    numbers.sort()
    msv = numbers[0]*numbers[1]
    lsv = numbers[len(numbers)-2]*numbers[len(numbers)-1]
    return max(msv, lsv)



"""
다항식 더하기
"""
def solution(polynomial):
    answer = [0, 0]
    values = polynomial.split()

    for i in values:
        if i == "+":
            continue

        if i == "x":
            answer[0] += 1
        elif "x" in i:
            i = i.replace("x", "")
            answer[0] += int(i)
        else:
            answer[1] += int(i)


    if answer[0] == 0:
        return str(answer[1])
    elif answer[1] == 0:
        return (str(answer[0]) + "x") if (answer[0] != 1) else ("x")
    else:
        result = (str(answer[0]) + "x") if (answer[0] != 1) else ("x")
        return result +" + " + str(answer[1])

solution("3x + 7 + x")