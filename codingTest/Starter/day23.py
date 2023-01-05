"""
특이한 정렬
"""
def solution(numlist, n):
    setList = []
    answer = []
    size = len(numlist)

    if size == 1:
        return numlist

    for i in range(size):
        setList.append((abs(numlist[i] - n), n - numlist[i]))
    setList.sort()

    print(setList)


solution([1, 2, 3, 4, 5, 6], 4)



"""
등수 매기기
"""
def solution(score):
    answer = [0]*len(score)
    avgList = []

    for i in range(len(score)):
        avgList.append(((sum(score[i])/len(score[i])),i))
    avgList.sort(reverse=True)

    rank = 0
    for i in range(len(avgList)):
        rank += 1

        if i == 0:
            answer[avgList[i][1]] = rank
            continue

        if avgList[i][0] == avgList[i-1][0]:
            answer[avgList[i][1]] = answer[avgList[i-1][1]]
        else:
            answer[avgList[i][1]] = rank

    return answer

solution([[80, 70], [70, 80], [30, 50], [90, 100], [100, 90], [100, 100], [10, 30]])

"""
옹알이 (1)
"""
def solution(babbling):
    babbleList = ["aya", "ye", "woo", "ma"]
    answer = []

    for word in babbling:
        for babble in babbleList:
            word = word.replace(babble, " ")
        answer.append(word)

    for word in answer:
        

    return answer.count("")

solution(["aya", "yee", "u", "maa", "wyeoo"])


"""
로그인 성공?
"""
def solution(id_pw, db):
    userId = id_pw[0]
    userPw = id_pw[1]
    fail_msg = "fail"
    
    for row in db:
        if (userId == row[0]) and (userPw == row[1]):
            return "login"
        if (userId == row[1]):
            fail_msg = "wrong pw"
    
    return fail_msg

