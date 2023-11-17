"""
컨틀롤 제트
"""

def solution(s):
    answer = 0
    zList = s.split()
    for i in range(len(zList)):
        if zList[i] == 'Z':
            answer -= int(zList[i-1])
        else:
            answer += int(zList[i])
    return answer

"""
배열 원소의 길이
"""
def solution(strlist):
    answer = []
    for str in strlist:
        answer.append(len(str))
    return answer


"""
중복된 문자 제거
"""
def solution(my_string):
    answer = ''
    strList = []
    for ch in my_string:
        if ch not in strList:
            answer += ch
            strList.append(ch)
    return answer


"""
삼각형의 완성조건 (1)
"""
def solution(sides):
    maxVal = max(sides)
    if maxVal < sum(sides) - maxVal:
        return 1
    else:
        return 2
