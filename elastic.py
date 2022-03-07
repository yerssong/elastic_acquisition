# Developed by YES

from elasticsearch import Elasticsearch
import tabulate
import csv
from pathlib import Path
import argparse

tabulate.WIDE_CHARS_MODE = True


def elastic_connect(ip, port, user, pwd):
    if user and pwd:
        host = user + ':' + pwd + '@' + ip + ':' + port
    else:
        host = ip + ':' + port
    es = Elasticsearch(hosts=host)

    return es

def adjust_letter(value):
    tmp = list()
    for i in value:
        i = str(i)
        if len(i) > 15:
            i = i[:15] + '...'
            tmp.append(i)
        else:
            tmp.append(i)

    return tmp

def get_elastic_data(_index, es):
    data_list = list()
    table_list = list()
    count = es.count(index=_index)['count']
    body = body_settings(count)
    res = es.search(index=_index, body=body)
    for j, source in enumerate(res['hits']['hits']):
        if j == 0:
            data_list.append(list(source['_source'].keys()))
            table_list.append(list(source['_source'].keys()))
            value = list(source['_source'].values())
            data_list.append(value)
            table_list.append(adjust_letter(value))
        else:
            value = list(source['_source'].values())
            data_list.append(value)
            table_list.append(adjust_letter(value))
    if table_list == []:
        pass
    else:
        print(tabulate.tabulate(table_list, headers="firstrow", tablefmt='github', showindex=True))

    return data_list

def get_elastic_index(es):
    _index = es.indices.get_alias('*')
    _index_list = list(_index.keys())

    return _index_list

def body_settings(count):
    if count >= 10000:
        body = {"size": 10000, "query": {"match_all": {}}}
    else:
        body = {"query": {"match_all": {}}}

    return body

def csv_export(data, _index, _path):
    Path(_path + '/elk_acquisition/result').mkdir(parents=True, exist_ok=True)
    with open(_path + '/elk_acquisition/result/' + _index + '.csv', 'a', newline='', encoding='utf-8-sig') as f:
        write_csv = csv.writer(f)

        for d in data:
            write_csv.writerow(d)

def main():
    parser = argparse.ArgumentParser(description='test')
    parser.add_argument('--path', default='./')
    args = parser.parse_args()
    _path = args.path

    print('------------------------------------------------------------------')
    print("[*] Enter your Elasticsearch Connection info")
    print('------------------------------------------------------------------')
    ip = str(input("[*] IP Address: "))
    port = str(input("[*] Port Num(Default: 9200): "))
    if ip is None:
        print('[*] Confirm Your IP Address and Port')
    print('------------------------------------------------------------------')
    print("[*] Enter your Elasticsearch Account info")
    print("[*] If you don't have authentication information, press Enter.")
    print('------------------------------------------------------------------')
    user = input("[*] Account Name: ")
    pwd = input("[*] Password: ")
    print('------------------------------------------------------------------')
    try:
        es = elastic_connect(ip, port, user, pwd)
        index_list = get_elastic_index(es)

        for _index in index_list:
            data = get_elastic_data(_index, es)
            csv_export(data, _index, _path)
    except:
        print("Check whether the Elastic Search input information is executed or not")

if __name__ == '__main__':
    main()
