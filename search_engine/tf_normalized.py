import math

def normalized_term_frequency(word, document):
    raw_frequency = document.count(word)
    if raw_frequency == 0:
        return 0
    return 1 + math.log(raw_frequency)