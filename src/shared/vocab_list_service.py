import sys
sys.path.append('../tests/')

# Temporary service until vocab lists are dynamic and stored in DynamoDB

def get_vocab_lists():
    return [
    {
      "list_name": "HSK Level 1",
      "list_id": "1",
      "list_difficulty_level": "Beginner",
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    },
    {
      "list_name": "HSK Level 2",
      "list_id": "2",
      "list_difficulty_level": "Beginner",
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    },
    {
      "list_name": "HSK Level 3",
      "list_id": "3",
      "list_difficulty_level": "Intermediate",      
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    },
    {
      "list_name": "HSK Level 4",
      "list_id": "4",
      "list_difficulty_level": "Intermediate",
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    },
    {
      "list_name": "HSK Level 5",
      "list_id": "5",
      "list_difficulty_level": "Advanced",      
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    },
    {
      "list_name": "HSK Level 6",
      "list_id": "6",
      "list_difficulty_level": "Advanced",
      "date_created": "2018-12-16T23:06:48.467526",
      "created_by": "admin"
    }
]