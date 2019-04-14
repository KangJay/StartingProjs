from flask import Flask, flash, redirect, render_template, request, url_for
import application
import boto3, botocore
import urllib.request
import time
application = Flask(__name__)
application.secret_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXX'

s3 = boto3.resource('s3')
#IAM user credentials weren't working for DynamoDB
session = boto3.Session( 
    aws_access_key_id="XXXXXXXXXXXXXXXXXX",
    aws_secret_access_key="XXXXXXXXXXXXXXXXXXXXXXXX",
    region_name='us-west-2')
db = session.resource('dynamodb', region_name='us-west-2')
table = db.Table('JiKang_userDBTable')
bucket_name = "jikangprog4bucket"
data_url = "https://s3-us-west-2.amazonaws.com/css490/input.txt"
#data_url = "https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sns.html"
#data_url = "https://s3-us-west-2m/css490/input.txt"
key_name = 'userDB.txt'
is_loaded = False #control where or not we can query


def create_table():
    try:
        user_data = s3.Object(bucket_name, key_name) # get the text data
        userDict = (user_data.get()['Body'].read().decode('utf-8')).split("\n")
        listOfDicts = list() #parse into multiple records
        for element in userDict:
            record = element.split() #each record is parsed by its attributes
            tempDict = ({'lastName':record[0], 'firstName':record[1]}) #last name + first Name
            for attributes in record[2:]: # Get everything other than lastname and firstname
                attribute = attributes.split("=") #Split attributes on =
                tempDict[attribute[0]] = attribute[1]
            listOfDicts.append(tempDict) #append to records 
        for record in listOfDicts: #upload each record
            table.put_item(Item=record)     
    except botocore.exceptions.ClientError as e:
        flash("here")
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            flash("Table unable to be found")


def load_data(): #do some parsing here too
    global is_loaded
    try:
        with urllib.request.urlopen(data_url) as url: #Load data
            flash("Loading data...") 
            input = url.read().decode()
            s3.Bucket(bucket_name).put_object(Key=key_name, Body=input, ACL='public-read')
            create_table()
            flash("Data loaded!")
            is_loaded = True 
    except botocore.exceptions.ClientError as e:
        flash("UGH")
    except urllib.error.URLError as urlE: 
        try: #Retry attempt 1
            time.sleep(2)
            with urllib.request.urlopen(data_url) as url2:
                flash("Unable to get data... Attempt #2...") 
                input = url2.read().decode()
                s3.Bucket(bucket_name).put_object(Key=key_name, Body=input, ACL='public-read')
                create_table()
                flash("Data loaded!")
                is_loaded = True 
        except urllib.error.URLError as UrlE2: 
            try:    #Retry attempt 2
                time.sleep(4)
                with urllib.request.urlopen(data_url) as url3:
                    flash("Unable to get data... Attempt #2...") 
                    input = url3.read().decode()
                    s3.Bucket(bucket_name).put_object(Key=key_name, Body=input, ACL='public-read')
                    create_table()
                    flash("Data loaded!")
                    is_loaded = True 
            except urllib.error.URLError as UrlE3:
                flash("Unable to hit site... Site may be down. Please try again later...")


def clear_data():
    global is_loaded
    try:
        flash("Clearing data...")
        s3.Object(bucket_name, key_name).load() #.load() will return an exception if not there
        s3.Object(bucket_name, key_name).delete()
        scan = table.scan()
        for ele in scan['Items']:
            table.delete_item(Key={'lastName':ele['lastName'], 'firstName':ele['firstName']})
        flash("Data cleared successfully!") #If an earlier exceptioon was not thrown, it'll flash true
        is_loaded = False
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            flash("Data already cleared.") #If object doesn't exist, we already cleared it 


def format_multiple_recs(multiList): #Print out the results formatted
    flash("RESULTS:")
    flash("Format: Last Name, First Name")
    for record in multiList:
        attr = "--Attributes--> " 
        flash("")
        flash(record['lastName'] + ", " + record['firstName'])
        del record['lastName']
        del record['firstName']
        for key, val in record.items():
            attr += key + ": " + val + ", "
        flash(attr)
    #return render_template('home.html', records=multiList)


def query_data(firstName, lastName):
    global is_loaded
    multiList = list() #holds all queries data
    if not is_loaded:
        flash("Please load data first before querying") 
    elif not firstName and not lastName:
        flash("Enter a first name, last name, or both")
    elif not firstName: #do last name
        response = table.scan()['Items']
        for recordDict in response: 
            if recordDict['lastName'] == lastName: multiList.append(recordDict)
        if len(multiList) == 0: flash("No entry with matching last name")
        else: 
            format_multiple_recs(multiList)
    elif not lastName: #do first name
        response = table.scan()['Items']
        for recordDict in response: 
            if recordDict['firstName'] == firstName: multiList.append(recordDict)
        if len(multiList) == 0: flash("No entry with matching firstname")
        else: 
            format_multiple_recs(multiList)
    else: 
        try:
            response = table.get_item(Key={'lastName':lastName, 'firstName':firstName})
            record = response['Item']
            tempList = list()
            tempList.append(record)
            format_multiple_recs(tempList)
            
        except Exception as e:
            flash("Entry does not exist in the database")


@application.route('/')
@application.route('/', methods=['GET', 'POST'])
def home():
    error = None
    if request.method == 'POST': #filter out results based on buttons
    	if request.form['enter_button'] == 'Load Data':
            load_data()
    	    #return "Loading data"
    	elif request.form['enter_button'] == 'Clear Data':
            clear_data()
    		#return "Clearing data"	#Clear DynamoDB + S3 Object
    	elif request.form['enter_button'] == 'Query':
            query_data(request.form['firstName'], request.form['lastName'])
    		#firstName = request.form['firstName']
    		#lastName = request.form['lastName']
    		#return "Hello " + firstName + " " + lastName
        
    return render_template('home.html', error=error)

if __name__ == "__main__":
    application.run(debug=True)
