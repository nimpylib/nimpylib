discard """
    output: '''
[4, 6]
[14, 15, 19, 20]
'''
"""
import pylib

def g():
    values = [i*2 `for` i in [1, 2, 3] `if` i > 1]
    print(values)

    sets = {i*2 `for` i in {1, 2} `if` i > 0}
    assert 2 in sets
    assert 4 in sets
    
    v2 = [i*5+j `for` i in [1, 2, 3] `for` j in [4, 5] `if` i > 1]
    print(v2)
g()

