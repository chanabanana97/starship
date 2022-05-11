import requests
import os
import hvac
from pymongo import MongoClient
from flask import Flask, render_template, request

app = Flask(__name__)
FLASK_APP = 'rezilion'

# connect to vault
vault_client = hvac.Client(
    url='http://myvault:8200',
    token='root',
)

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')


def connect_to_db():
    client = MongoClient(
        host=os.getenv('DB_URL'), port=27017,
        serverSelectionTimeoutMS=3000,  # 3 second timeout
        username=os.getenv('MONGO_INITDB_ROOT_USERNAME'),
        password=os.getenv('MONGO_INITDB_ROOT_PASSWORD'),
        authSource='admin'
    )
    return client['super_db']

# @app.route('/getCheapest/<product_name>', methods=['GET'])
@app.route('/getCheapest', methods=['POST'])
def get_cheapest():

    product_name = request.form["item"]
    url = 'https://api.superget.co.il/'
    # store_id_list = [305, 28, 148]
    # api_key = os.getenv('api_key')

    read_response = vault_client.secrets.kv.read_secret_version(path='data')
    api_key = read_response['data']['data']['apikey']

    data = {'api_key': api_key}
    store_id_list = os.getenv('store_id_list').split(',')
    store_id_list.sort()
    db = connect_to_db()
    collec = db.get_collection('super_tb')

    doc = collec.find_one({"product_name": product_name, "store_id_list": store_id_list})
    if doc is not None:
        data = "cheapest store is: " + str(doc["cheapest_store"]) + " with price of " + str(doc["cheapest_price"])
        return render_template('index.html', data=data)


    # get the details of the product (product id)
    data['action'] = 'GetProductsByName'
    data['product_name'] = product_name
    product_by_name_req = requests.get(url=url, params=data).json()[0]
    product_id = product_by_name_req['product_id']

    # get the price of the product from each store in store_id_list
    prices = {}
    data.pop('product_name', None)
    data['action'] = 'GetPriceByProductID'
    data['product_id'] = product_id
    for store_id in store_id_list:
        data['store_id'] = str(store_id)
        price_by_id_req = requests.get(url=url, params=data).json()[0]
        store_name = price_by_id_req['chain_name']
        price = price_by_id_req['store_product_price']
        prices[store_name] = price

    cheapest = min(prices.items(), key=lambda k: k[1])

    # add to mongodb
    data_to_add = {"product_name": product_name, "store_id_list": store_id_list, "cheapest_store":cheapest[0], "cheapest_price":cheapest[1]}
    collec.insert_one(data_to_add)

    data = f"Cheapest store is {cheapest[0]} with the price of {cheapest[1]}"
    return render_template('index.html', data=data)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
