from chatterbot import ChatBot
from chatterbot.trainers import ListTrainer


my_bot = ChatBot(name='PyBot', read_only=True,
                logic_adapters=
['chatterbot.logic.MathematicalEvaluation',
                    'chatterbot.logic.BestMatch'])


small_talk = ['hi there!',
            'hi!',
            'how do you do?',
            'how are you?',
            'i am cool.',
            'fine, you?',
            'always cool.',
            'i am ok',
            'glad to hear that.',
            'i am fine',
            'glad to hear that.',
            'i feel awesome!',
            'excellent, glad to hear that.',
            'Actually not so good',
            'So sorry to hear that.',
            'what is your name',
            'I am pybot. ask me a math question, please.']

math_talk_1 = ['pythagorean theorem',
                'x squared plus y squared equals z squared.']

math_talk_2 = ['law of cosines',
                'c**2 = a**2 + b**2 - 2 * a * b * cos (gamma)']


# Train it with another collection of stings
list_trainer = ListTrainer(my_bot)
for item in (small_talk, math_talk_1, math_talk_2):
    list_trainer.train(item)


# Train itself
#from chatterbot.trainers import ChatterBotCorpusTrainer
#corpus_trainer = ChatterBotCorpusTrainer(my_bot)
#corpus_trainer.train('chatterbot.corpus.english')
