def docs_contain_word(word, documents):
	counter = 0
	for document in list_of_documents:
		if word in document:
			counter+=1
	
	return counter

def get_vocabulary(documents):
	vocabulary = set([word for document in documents for word in document])	
	
	return vocabulary

def inverse_document_frequency(documents, vocabulary):

	idf = {}
	
	for word in vocabulary:
		contains_word = docs_contain_word(word, documents)
		idf[word] = 1 + math.log(len(documents)/(contains_word))
        
	return idf