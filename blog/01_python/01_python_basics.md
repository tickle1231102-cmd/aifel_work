---
title: "Python 기초 - 변수와 자료형"
date: 2026-08-31
category: "Python"
tags: ["python", "basics", "variables", "types"]
author: "tickle1231102"
---

# Python 기초 - 변수와 자료형

Python을 처음 시작하는 분들을 위한 기초 개념 정리입니다.

## 변수(Variable)란?

변수는 데이터를 저장하는 상자라고 생각하면 됩니다. Python에서는 매우 간단하게 변수를 선언할 수 있습니다.

```python
# 변수 선언
name = "Jack"
age = 25
height = 175.5

print(name)    # Jack
print(age)     # 25
print(height)  # 175.5
```

## Python의 기본 자료형

### 1. 문자열(String)

```python
message = "Hello, Python!"
empty_string = ""

# 문자열 연결
greeting = "Hello" + " " + "World"
print(greeting)  # Hello World

# 문자열 반복
repeated = "Ha" * 3
print(repeated)  # HaHaHa
```

### 2. 정수(Integer)

```python
number = 42
negative = -10
zero = 0

# 기본 연산
result = 10 + 5
print(result)  # 15

# 거듭제곱
power = 2 ** 8
print(power)  # 256
```

### 3. 실수(Float)

```python
pi = 3.14159
temperature = -15.5

# 실수 연산
area = 3.14 * 5 * 5
print(area)  # 78.5
```

### 4. 불린(Boolean)

```python
is_active = True
is_deleted = False

# 비교 연산
age = 25
is_adult = age >= 18
print(is_adult)  # True
```

## 자료형 확인하기

```python
value = 42
print(type(value))  # <class 'int'>

value = "Hello"
print(type(value))  # <class 'str'>

value = 3.14
print(type(value))  # <class 'float'>
```

## 형 변환(Type Conversion)

```python
# 문자열을 정수로
num_str = "123"
num = int(num_str)
print(num)  # 123

# 정수를 문자열로
number = 42
text = str(number)
print(text)  # "42"

# 정수를 실수로
value = float(10)
print(value)  # 10.0
```

## 변수 명명 규칙

```python
# ✅ 올바른 명명
user_name = "Jack"
age25 = 25
_private = "private"

# ❌ 잘못된 명명
# 25age = 25  # 숫자로 시작할 수 없음
# user-name = "Jack"  # 하이픈 사용 불가
# class = "Python"  # 예약어 사용 불가
```

## 결론

Python의 변수와 자료형은 매우 직관적입니다. 다음 학습으로는 리스트, 딕셔너리 같은 컬렉션 자료형을 배워보세요!

## 참고 자료

- [Python 공식 문서](https://docs.python.org/3/)
- [Python 자료형 가이드](https://www.python-guide.org/)
