import numpy as np

def most_similar(similarity_list, min_talks=1):
	
	most_similar= []
  
	while min_talks > 0:
		tmp_index = np.argmax(similarity_list)
		most_similar.append(tmp_index)
		similarity_list[tmp_index] = 0
		min_talks -= 1

	return most_similar