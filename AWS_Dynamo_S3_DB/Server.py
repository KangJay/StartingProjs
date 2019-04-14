import boto3, botocore
import urllib.request, os

s3 = boto3.resource('s3')
#s3 = boto3.client('s3')
#s3_1 = boto3.resource('s3')
#bucket = s3.Bucket('jikangprog4bucket')
# https://css490.blob.core.windows.net/lab4/input.txt
# https://s3-us-west-2.amazonaws.com/css490/input.txt


# https://stackoverflow.com/questions/36205481/read-file-content-from-s3-bucket-with-boto3
def main():

    with urllib.request.urlopen("https://css490.blob.core.windows.net/lab4/input.txt") as url:
        input = url.read().decode()
        #file = open('css490_temporary.txt', 'w+')
        #file.write(input)
        #file.close()

        s3.Bucket('jikangprog4bucket').put_object(Key='userDB.txt', Body=input, ACL='public-read')
        #s3.Object('jikangprog4bucket', 'css490_temporary.txt').put(Metadata={'creation':'success'})
        #s3.upload_file('css490_temporary.txt', 'jikangprog4bucket', 'css490_temporary.txt')
        #boto3.resource('s3').ObjectAcl('jikangprog4bucket', 'css490_temporary.txt').put(ACL='public-read')



if __name__ == "__main__":
    main()
