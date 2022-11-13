#getHolding.py

#from yahoo_fin.stock_info import get_data

#amazon_weekly= get_data("amzn", start_date="12/04/2009", end_date="12/04/2019", index_as_date = True, interval="1wk")

import boto3 
import yfinance as yf

#tickerFile="s3://spk-lambda-in/tickers.json"

s3=boto3.client('s3')
#s3.download_file('spk-lambda-in', 'tickers.json', 'temp.json')
s3_bucket_name= 'spk-lambda-in'
s3_object_name= 'tickers.json'
response=s3.get_object(Bucket=s3_bucket_name, Key=s3_object_name)
tickers=response['Body'].read()

yesterday=yf.download(tickers)