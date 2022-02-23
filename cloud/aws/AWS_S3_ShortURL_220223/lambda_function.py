import short_url
import json
import boto3
import botocore
import os
from botocore.client import Config

BUCKET_NAME = os.environ["BUCKET_NAME"]
PREFIX = os.environ['PRE_FIX']
S3_CLIENT = boto3.client('s3')
S3_RESOURCE = boto3.resource('s3')
# URL을 만들 때 사용할 문자들, block_size 조정
shortener = short_url.UrlEncoder("PbNVLaqiJjMzHvTRs2ex35yXockGwCg8Bp7ESFZQtduWn6KAYm9r1DhU4f", 32)

def exists_s3_key(key):
  try:
    resp = S3_CLIENT.head_object(Bucket=BUCKET_NAME, Key=key)
    return True
  except botocore.exceptions.ClientError as e:
    if (e.response['Error']['Code'] == "404"): return False
    if (e.response['Error']['Code'] == "403"): return False
    raise e     

def lambda_handler(event, context):
    
  # 파라미터 가져오기
  long_url = event.get("long_url")
  number = event.get("number")

  # long_url 자체를 인코딩하지 않고 number를 이용해서 인코딩
  encode_uri = shortener.encode_url(number)
    
  # s3 저장 위치, 오브젝트 이름
  obj_key = "surl/"+encode_uri
    
  # 이미 존재하는 key 인지 확인
  if (exists_s3_key(obj_key)):
    print("Object Key is Collision")
    return { "short_url": "", "result":"ERROR" }
  else:
    print("Object Key Find!! "+obj_key)
    
  # s3 저장    
  print("Object Save...")
  resp = S3_CLIENT.put_object(Bucket=BUCKET_NAME,
                       Key=obj_key,
                       Body=b"",
                       WebsiteRedirectLocation=long_url, # redirect location
                       ContentType="text/plain")
    
  print("Saved!!")
    
  ret_url = PREFIX+"/"+obj_key    
  print("Return value is "+ret_url)
    
  return { "short_url": ret_url, "result":"OK" }