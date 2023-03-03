class SNS:
    def __init__(self, topic, subject, message):
        self.__topic = topic
        self.__subject = subject
        self.__message = message
    
    def __del__(self):
        del self.topic
        del self.subject
        del self.message

    @property
    def topic(self):
        return self.__topic
    
    @property
    def subject(self):
        return self.__subject

    @property
    def message(self):
        return self.__message

    def sendMail():
        pass