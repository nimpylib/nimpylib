discard """
    output: '''
[4, 6]
[14, 15, 19, 20]
'''
"""
import pylib

def g():
    values = [i*2 | i in [1, 2, 3], i > 1]
    print(values)

    sets = {i*2 | i in {1, 2}}
    assert 2 in sets
    assert 4 in sets
    
    v2 = [i*5+j | i in [1, 2, 3], j in [4, 5], i > 1]
    print(v2)
g()

