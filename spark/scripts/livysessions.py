import requests
import json
import traceback
import time


def handle_argument():
    '''handle the argument. '''
    import argparse

    description = 'This script is used to import data from db into hdfs using spark sql.'
    epilog = """ """
    parser = argparse.ArgumentParser(prog="livysessions",
                                     description=description,
                                     epilog=epilog,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    subparsers = parser.add_subparsers(dest='action', help='sub-command help')
    add_parser = subparsers.add_parser('add', help='add one livy session if there is none.')
    add_parser.add_argument('--livyRootUrl', nargs='?',
                            default='http://spark-master0:8998', help='livy server root url.')

    clean_parser = subparsers.add_parser('lessen', help="delete extra sessions if there are more sessions.")
    clean_parser.add_argument('--livyRootUrl', nargs='?',
                              default='http://spark-master0:8998', help='livy server root url.')

    clean_parser = subparsers.add_parser('clean', help="clean all sessions.")
    clean_parser.add_argument('--livyRootUrl', nargs='?',
                              default='http://spark-master0:8998', help='livy server root url.')

    return parser


parser = handle_argument()
args = parser.parse_args()


def handleLivySessions(manageType,
                       livyRootUrl='http://spark-master0:8998',
                       pyFiles=[]):
    '''
    manageType is one of ['clean', 'add', 'lessen']
    '''
    rootUrl = livyRootUrl
    sessionData = {
        'kind': 'pyspark3',
        'pyFiles': pyFiles
    }
    headers = {'Content-Type': 'application/json'}

    rootSessionsUrl = rootUrl + '/sessions'
    maxSteps, step, loopFlag = 30, 0, True
    while step < maxSteps and loopFlag:
        try:
            curSessionsReqJson = requests.get(rootSessionsUrl, headers=headers).json()
            loopFlag = False
        except Exception:
            time.sleep(1)
            step += 1
            if step == maxSteps:
                traceback.print_exc()
                return False
            else:
                print("Fail to get session from livy server. Retry it again.")

    if manageType == 'lessen':
        # If there are many sessions, clean the sessions whose state is in the sessionState list.
        # As for the last one, delete it if this session state is in the ['error', 'dead', 'success'] list
        if (curSessionsReqJson['total'] > 0):
            sessionStates = ['idle', 'error', 'shutting_down', 'dead', 'success']
            for sessionItem in curSessionsReqJson['sessions'][:-1]:
                if (sessionItem['state'] in sessionStates):
                    sessionUrl = "{0}/{1}".format(rootSessionsUrl, sessionItem['id'])
                    requests.delete(sessionUrl)
                    print("delete session:{0} sucessfully".format(sessionUrl))
            # handle the last one session specially
            lastOneStatesLt = ['error', 'dead', 'success']
            if curSessionsReqJson['sessions'][-1]['state'] in lastOneStatesLt:
                sessionUrl = "{0}/{1}".format(rootSessionsUrl, curSessionsReqJson['sessions'][-1]['id'])
                requests.delete(sessionUrl)
                print("delete session:{0} sucessfully".format(sessionUrl))
        else:
            pass
    if manageType == 'clean':
        # clean all the sessions.
        if (curSessionsReqJson['total'] > 0):
            for sessionItem in curSessionsReqJson['sessions']:
                sessionUrl = "{0}/{1}".format(rootSessionsUrl, sessionItem['id'])
                requests.delete(sessionUrl)
                print("delete session:{0} sucessfully".format(sessionUrl))
        else:
            pass
    elif manageType == 'add':
        # If there is no session, create a new one
        if (curSessionsReqJson['total'] > 0):
            pass
        else:
            requests.post(
                rootSessionsUrl, data=json.dumps(sessionData), headers=headers).json()
            print("create a new session sucessfully")
    else:
        pass


if args.action == "add":
    handleLivySessions('add', args.livyRootUrl)
elif args.action == "lessen":
    handleLivySessions('lessen', args.livyRootUrl)
elif args.action == "clean":
    handleLivySessions('clean', args.livyRootUrl)
else:
    pass
