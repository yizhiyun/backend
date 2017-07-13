import requests

def cleanUnUsedLivySessions(sparkHost = 'http://spark-master0:8998', \
        sessionState=['idle', 'error', 'shutting_down', 'dead', 'success'], pyFiles = []):
    '''
    '''
    host = sparkHost
    sessionData = {
        'kind': 'pyspark',
        'pyFiles': pyFiles
        }
    headers = {'Content-Type': 'application/json'}
    
    
    rootSessionsUrl = host + '/sessions'
    curSessionsReqJson = requests.get(rootSessionsUrl, headers=headers).json()
    # If there are many sessions, clean the sessions whose state is in the "sessionState" list.
    # As for the last one, delete it if this session state is in the ['error', 'dead', 'success'] list
    if (curSessionsReqJson['total'] > 0):
        
        for sessionItem in curSessionsReqJson['sessions'][:-1]:
            if (sessionItem['state'] in sessionState) :
                sessionUrl = "{0}/{1}".format(rootSessionsUrl, sessionItem['id'])
                requests.delete(sessionUrl)
        # handle the last one session specially
        lastOneStatesLt = ['error', 'dead', 'success']
        if curSessionsReqJson['sessions'][-1]['state'] in lastOneStatesLt:
            sessionUrl = "{0}/{1}".format(rootSessionsUrl, curSessionsReqJson['sessions'][-1]['id'])
            requests.delete(sessionUrl)
    else:
        pass

cleanUnUsedLivySessions()
