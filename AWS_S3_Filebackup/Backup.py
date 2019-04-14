import boto3, botocore
import time
import argparse
import os

#Author: Ji Kang

s3 = 0 #place holder
all_files = list() #Hold all
#Arg parser fields 
parser = argparse.ArgumentParser(description='Back up files and all subdirectories the current directory the program is run in')
parser.add_argument('-bn', '--bucketname', type=str, default='JiKangprog490test', help='Bucket name to create/access to back up the files in.')
parser.add_argument('-reg', '--region', type=str, default='us-west-2', help='Region where your AWS IAM User configurations are set to.')
args = parser.parse_args()

#Do not change
region = args.region.lower()
bucket_name = args.bucketname.lower()


def delete_files(deleted_items):
	def delete_list():
		for key in deleted_items:
			deleted_items.remove(key)
			print("Deleting file:", key)
			s3.Object(bucket_name, key).delete()
	print("\nDeleted files detected on local machine. ")
	print("Enter 'all' to remove all deleted files. ")
	userInput = input("Enter 'none' to not delete any: ")
	if (userInput.upper() == "ALL"): delete_list()
	elif (userInput.upper() == "NONE"): return


def check_deleted_files():
	deleted_items = list()
	for obj in s3.Bucket(bucket_name).objects.all():
		if obj.key not in all_files and obj.key != "Backup.py": deleted_items.append(obj.key)
	if (len(deleted_items) > 0): delete_files(deleted_items)

#Get last modified date. index 8 = last modified date in the tuple 
def get_mdate(file): return os.stat(file)[8]

#Main recursive method for backing up files 
def backup_files(path, subdir):
	for filename in os.listdir(path):
		filePath = path + "/" + filename #Extend file path
		if (os.path.isdir(filePath)): #Check if it's a directory
			tempSubdir = ""
			if subdir: tempSubdir = subdir + "/" + filename #Modify subdir variable accordingly
			else: tempSubdir = filename	
			backup_files(filePath, tempSubdir)
		else: #Do the comparisons and backup here. Not a directory, just a file
			fileKey = subdir
			if subdir: fileKey = subdir + "/" + filename	#File key is dependent on if subdir is empty or not
			else: fileKey = filename
			all_files.append(fileKey)
			try:
				s3.Object(bucket_name, fileKey).load()
				if int(s3.meta.client.head_object(Bucket=bucket_name, Key=fileKey)["Metadata"]["mod_date"]) < get_mdate(filePath):
					print("Updating file:", filename)
					s3.Object(bucket_name, fileKey).put(Body='data', Metadata={'mod_date': str(get_mdate(filePath))})
			except botocore.exceptions.ClientError as e:
				err = e.response['Error']['Code']
				if err == "404": #Object doesn't exist so upload it
					if filename != "Backup.py": #don't upload the program itself
						print("Uploading file:", filename)
						s3.Object(bucket_name, fileKey).put(Body='data', Metadata={'mod_date': str(get_mdate(filePath))})

#Get cwd and call recursive method 
def get_path():
	print("Starting to backup files...\n")
	backup_files(os.getcwd(), "")
	print("\nDone backing up files!")
	check_deleted_files()


def create_S3Bucket():
	print("Attempting to create bucket:", bucket_name)
	try:
		if region != "us-east-1": s3.create_bucket(Bucket=bucket_name, CreateBucketConfiguration={"LocationConstraint": region})
		else: s3.create_bucket(Bucket=bucket_name) #Can't specify us-east-1 in location constraint
		print("Bucket:", bucket_name, "successfully created.")
		get_path()
	except botocore.exceptions.ClientError as e:
		err = e.response['Error']['Code']
		if err == "OperationAborted":
			print("Bucket name is available but may have recently been in use. Allow AWS to reconfigure bucket names")
			print("Bucket name in question:", bucket_name)
		if err == "InvalidBucketName":
			print("\nInvalid bucket name. Please re-run with a valid bucket name.")
			print("Bucket Naming Guidelines can be found here: \nhttps://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html")
		if err == "IllegalLocationConstraintException":
			print("\nIllegalLocationConstraintException thrown...")
			print("Not a valid region. Either it's not your default region or does not exist")
			print("AWS Regions and Endpoints found here:\nhttps://docs.aws.amazon.com/general/latest/gr/rande.html")
		return False


def main():
	global s3
	s3 = boto3.resource('s3')
	try:
		s3.meta.client.head_bucket(Bucket=bucket_name) 
		get_path()	#If bucket exists and we have access
		return True
	except botocore.exceptions.ClientError as e:
		err_code = int(e.response['Error']['Code'])
		if err_code == 403:
			print("Either a private bucket or your credentials are invalid. Check your AWS credentials and/or bucket name")
			return False
		elif err_code == 404: # Doesn't exist. Create it first.
			create_S3Bucket()


if __name__ == "__main__":
	print("Running Ji Kang's AWS S3 File Backup Program...")
	print("Will upload the current directory, its files, and any subdirectories and their files to an S3 Bucket")
	try:
		main()
	except botocore.exceptions.EndpointConnectionError as e:
		try:
			print("Cannot connect to AWS S3. Attempt number 2...") #retry logic
			time.sleep(2)
			main()
		except botocore.exceptions.EndpointConnectionError as e2:
			try:
				print("Cannot connect to AWS S3. Attempt number 3...") #retry logic
				time.sleep(4)
				main()
			except botocore.exceptions.EndpointConnectionError as e3:
				print("AWS S3 may be down or your internet connection may not be stable. Please retry again later!")
