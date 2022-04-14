from nltk.tokenize import word_tokenize
from nltk import FreqDist

documents = ["I enjoy watching movies when it's cold outside",
 "Toy Story is the best animation movie ever",
 "Watching horror movies alone at night is really scary",
 "He loves films filled with suspense and unexpected plot twists ",
 "This is one of the most overrated movies I've ever seen"]

tokens = sum([word_tokenize(document) for document in documents], [])
words_frequency = FreqDist(tokens)
words_frequency.plot(30, cumulative = False)


