from sklearn.metrics.pairwise import cosine_similarity

def cos_similarity(search_query_weights, tfidf_weights_matrix):
	
	cosine_distance = cosine_similarity(query, tfidf_matrix)
	similarity_list = cosine_distance[0]
  
	return similarity_list
    