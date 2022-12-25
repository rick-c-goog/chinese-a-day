import os
from google.cloud import firestore_v1
#from boto3.dynamodb.conditions import Key, Attr

import sys
sys.path.append('../tests/')

#table = boto3.resource('dynamodb', region_name=os.environ['AWS_REGION']).Table(os.environ['TABLE_NAME'])
firestore = firestore_v1.Client()
TABLE_NAME = "vocabulary"

# Returns all of the words (and details) associated with a given list
def get_words_in_list(list_id, limit=None, last_word_token=None, audio_file_key_check=False):

    try:
        query_ref = firestore.collection(TABLE_NAME).where("list_id", "==", list_id).stream()
        #query_response = query_dynamodb(list_id, limit=limit, last_word_token=last_word_token, audio_file_key_check=audio_file_key_check)
    except Exception as e:
        print(f"Error: Firestore query for word list failed.")
        print(e)
        return {
            f"error_message": "Failed to query DynamoDB. Error: {e}"
        }
    word_list = format_word_list(query_ref)

    return word_list


def format_word_list(query_response):
    word_list = []

    # Reformat item['Word'] contents to lower caps/underscores?
    for item in query_response:
        word_list.append(
            {
                "list_id": item['list_id'],
               # "word_id": item.id,
                "word": item['Word']
            }
        )
    return word_list
