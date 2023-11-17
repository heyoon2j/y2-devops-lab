# Day 9

"""
개미 군단
"""
def solution(hp):
    answer = 0
    antAttack = [5, 3, 1]
    if hp == 0:
        return answer

    for i in antAttack:
        answer += hp % i
        hp //= i

    return answer

"""
모스부호
"""
def solution(letter):
    morse = { 
        '.-':'a','-...':'b','-.-.':'c','-..':'d','.':'e','..-.':'f',
        '--.':'g','....':'h','..':'i','.---':'j','-.-':'k','.-..':'l',
        '--':'m','-.':'n','---':'o','.--.':'p','--.-':'q','.-.':'r',
        '...':'s','-':'t','..-':'u','...-':'v','.--':'w','-..-':'x',
        '-.--':'y','--..':'z'
    }
    answer = ''
    result = letter.split()
    
    for i in result:
        answer += morse[i]

    return answer

print(solution(".... . .-.. .-.. ---"))



"""
가위 바위 보
"""
def solution(rsp):
    answer = ''
    winDict = {"2":"0", "0":"5", "5":"2"}
    
    for i in range(len(rsp)):
        answer += winDict[rsp[i]]
    
    return answer


"""
구슬을 나누는 경우의 수
"""
def solution(balls, share):
    answer = 1

    if balls == share:
        return answer
    
    for i in range(balls, balls-share, -1):
        answer *= i
    for j in range(1, share+1):
        answer /= j

    return int(answer)







