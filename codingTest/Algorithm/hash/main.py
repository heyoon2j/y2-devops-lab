"""
포켓몬

1) N/2 가지고 간다.
2) 포켓몬의 종류에 따라 번호로 구분, 같은 종류의 포켓몬은 같은 번호를 가지고 있음 
3) 
"""

def solution(nums):
    answer = set()
    for num in nums:
        answer.add(num)
    
    if len(answer) >= len(nums) // 2:
        return len(nums) // 2
    else:
        return len(answer)



"""
위장

1) 매일 다른 옷을 조합하여 입음 (기존 옷에서 다른 종류가 추가되거나 다른 것으로 바꿔 입어야됨)
2) 
"""

def solution(clothes):
    answer = 1
    clothDict = dict()
    for cloth in clothes:
        if clothDict.get(cloth[1]) == None:
            clothDict[cloth[1]] = 1
        else:
            clothDict[cloth[1]] += 1

    for clothCnt in clothDict.values():
        answer *= (clothCnt+1)

    return answer - 1

solution([["yellow_hat", "headgear"], ["blue_sunglasses", "eyewear"], ["green_turban", "headgear"]])


"""
베스트앨범

1) 장르 별로 가장 많이 재생된 노래를 두 개씩 모아 베스트 앨범을 출시
2) 노래는 고유 번호로 구분
3) 장르, 노래 수록 순서
    1) 속한 노래가 많이 재생된 장르를 먼저 수록합니다.
    2) 장르 내에서 많이 재생된 노래를 먼저 수록합니다.
    3) 장르 내에서 재생 횟수가 같은 노래 중에서는 고유 번호가 낮은 노래를 먼저 수록합니다.
"""

def solution(genres, plays):
    answer = []

    musicDict = dict()
    playCount = []

    # 계산을 위해 분리
    for i in range(len(genres)):
        if musicDict.get(genres[i]) == None:
            musicDict[genres[i]] = [(plays[i], i)]
        else:
            musicDict[genres[i]].append((plays[i], i))
    
    for musicType in musicDict.keys():
        musicDict[musicType].sort(key = lambda x : (-x[0], x[1]))
        result = 0
        for music in musicDict[musicType]:
            result += music[0]
        playCount.append((result, musicType))

    # 순서 정하기
    playCount.sort()
    for play in playCount:
        musicType = play[1]
        if len(musicDict[musicType]) == 1:
            answer.append(musicDict[musicType][0][1])
        else:
            answer.append(musicDict[musicType][0][1])
            answer.append(musicDict[musicType][1][1])

    return answer

solution(["classic", "pop", "classic", "classic", "pop"],[500, 600, 150, 500, 2500])