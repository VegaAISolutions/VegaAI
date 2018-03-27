import csv
import os
from datetime import datetime

import pandas as pd
import numpy as np
from PyPDF2 import PdfFileReader, PdfFileWriter
from PyPDF2.generic import NameObject, BooleanObject
from flask import Flask, render_template, send_file, jsonify, url_for, redirect
from flask import request
from flask_socketio import SocketIO
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from werkzeug.utils import secure_filename

from Bots.currencybot import CurrencyBot
from Config.config import reports_db, uploads, downloads, taxreport_base
from app.taxreports.fifocalc import *

engine = create_engine('sqlite:///{}CryptoData.db'.format(reports_db), echo=True)
metadata = MetaData(bind=engine)
Base = declarative_base()

class Transactions(Base):
    __table__= Table('Transactions', metadata, autoload=True)

class Taxes(Base):
    __table__ = Table('Taxes', metadata, autoload=True)

Session = sessionmaker(bind=engine)
session = Session()

app = Flask(__name__)

app.config['UPLOAD_FOLDER'] = uploads
socketio = SocketIO(app)

def process_txnfiles(session):
    fieldnames = ['Date', 'DateSold', 'Exchange', 'Action', 'Coin', 'Volume', 'Price', 'Fees', 'Cost']
    directory = uploads
    for f in os.listdir(directory):
        try:
            if f.endswith(".csv"):
                with open(os.path.join(directory, f)) as csvDataFile:
                    csvReader = csv.DictReader(csvDataFile)
                    for row in csvReader:
                        try:
                            txn = Transactions()
                            txn.Id = row['Id']
                            txn.Date = row['Date']
                            txn.DateSold = row['DateSold']
                            txn.Exchange = row['Exchange']
                            txn.Action = row['Action']
                            txn.Coin = row['Coin']
                            txn.Volume = float(row['Volume'])
                            txn.Price = float(row['Price'])
                            txn.Fees = float(row['Fees'])
                            txn.Cost = row['Cost']

                            txn.Cost = (txn.Volume * txn.Price) + txn.Fees
                            txn.Cost = -txn.Cost

                            # TODO: refactor this, I was having an issue with trying to update.
                            #t = session.query(Transactions).filter((Transactions.Date == txn.Date and Transactions.DateSold == txn.DateSold and Transactions.Exchange == txn.Exchange and Transactions.Action == txn.Action)).first()
                            t = session.query(Transactions).filter(Transactions.Id == txn.Id).first()
                            if t == None:
                                session.add(txn)
                                session.commit()
                            else:
                                #currenttxn = session.query(Transactions).filter((Transactions.Date == txn.Date and Transactions.DateSold == txn.DateSold and
                                 #                                                      Transactions.Exchange == txn.Exchange and Transactions.Action == txn.Action)).first()

                                session.delete(t)
                                session.commit()
                                session.add(txn)
                                session.commit()
                        except Exception as e:
                            print(e)
                            session.rollback()
        except Exception as e:
            print(e)

def process_pdfs(directory, downloads):
    for f in os.listdir(directory):
        #if f.endswith('.pdf'):
            create_irs_1099k_csv(directory+f,downloads)


def messageReceived():
    print('message was received!!!')

@socketio.on('userevent')
def handle_my_custom_event(jsoninput):
    print('received my event: ' + str(jsoninput))
    cbot = CurrencyBot('Vega Currency Bot')
    bot_response = {}
    if 'data' in jsoninput != None and jsoninput['data'] == 'User Connected':
        bot_response = {'user_name': 'vegabot',
                        'message': 'Welcome to the Vega Interactive demo, please enter a user name and type a question to proceed!'}
        socketio.emit('vbotresponse', jsoninput, callback=messageReceived)
        socketio.emit('vbotresponse', bot_response)
    elif 'message' in jsoninput != None and jsoninput['message'] != '':
        bot_response = {'user_name': 'vegabot', 'message': 'Please wait a moment while I process your request.....'}
        socketio.emit('vbotresponse', bot_response, callback=messageReceived)
        socketio.sleep(1)
        bot_response = cbot.get_response_action(jsoninput['message'], jsoninput['user_name'])
        if type(bot_response) is list or type(bot_response) is tuple:
            for msg in bot_response:
                socketio.emit('vbotresponse', msg, callback=messageReceived)
        else:
           socketio.emit('vbotresponse', jsoninput, callback=messageReceived)
           socketio.emit('vbotresponse', bot_response)
    #reports(jsoninput)
# Handle the transactions and estimated taxes
@app.route('/reports', methods=['GET', 'POST'])
def reports(request=request,taxyear=2018):
    taxoptions = [{'type':'FIFO'},{'type':'LIFO'}]
    taxyearoptions = [{'year':2018}, {'year':2017}]
    print('Accounting method selected was ', request.form.get('method_select'))
    method = request.form.get('method_select')
    if request.form.get('year_select') is not None:
        taxyear = int(request.form.get('year_select'))
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        if request.method == 'POST':
            try:
                f = request.files['file']
                if f.filename != '':
                    f.save(os.path.join(uploads, secure_filename(f.filename)))
            except Exception as e:
                print(e)

            process_txnfiles(session)
            create_irs_csv(session,taxyear)
            create_irs_form(session,taxyear)
            process_pdfs(uploads, downloads)

        query = session.query(Transactions)
        txn_history = pd.read_sql(query.statement, query.session.bind, index_col=None)
        txn_history['Price'] = txn_history['Price'].map('${:,.2f}'.format).astype(str)
        txn_history['Fees'] = txn_history['Fees'].map('${:,.2f}'.format).astype(str)
        txn_history['Cost'] = txn_history['Cost'].map('${:,.2f}'.format).astype(str)

        count = session.query(Taxes).filter(Taxes.Year == taxyear).count()
        taxobj = Taxes()
        taxobj.Year = taxyear
        taxobj.Long_Term_Gains = 0.0
        taxobj.Long_Term_Tax = 0.0
        taxobj.Short_Term_Gains = 0.0
        taxobj.Short_Term_Tax = 0.0
        Cost_Basis = 0.0

        # work around until I can figure out the issue with the summation function in sql alchemy
        # for now use the Last in First out accounting method.
        # We have to figure out the cost basis and subtract it from the proceeds for each
        # date sold, basically if volume 2 then we really have two records with subtraction
        # from the previous day and then the day before that.
        '''Refactored to use the fifo class
        for currentrow in session.query(Transactions):
            y = datetime.strptime(currentrow.Date, '%m/%d/%Y%H:%M:%S').year
            if currentrow.Action == 'SELL':
                if y >= 2017:
                    taxobj.Short_Term_Gains += currentrow.Price + currentrow.Cost
                else:
                    taxobj.Long_Term_Gains += currentrow.Cost
        '''

        taxobj.Short_Term_Gains, taxobj.Short_Term_Tax, \
        taxobj.Long_Term_Gains, taxobj.Long_Term_Tax = calculate_gl_estimatedtaxes(session,current_tax_year=taxyear, method=method)

        #taxobj.Long_Term_Tax = taxobj.Long_Term_Gains * .15
        #taxobj.Short_Term_Tax = taxobj.Short_Term_Gains * .28

        taxobj.Total_Estimate = taxobj.Long_Term_Tax + taxobj.Short_Term_Tax
        if count == 0:
            session.add(taxobj)
            session.commit()
        else:
            currenttaxes = session.query(Taxes).filter(Taxes.Year == taxyear).first()
            session.delete(currenttaxes)
            session.commit()
            session.add(taxobj)
            session.commit()
        query = session.query(Taxes).filter(Taxes.Year == taxyear)
        taxes = pd.read_sql(query.statement, session.bind, index_col=None)

        taxes['Tax Year'] = taxyear
        taxes['Long Term Gains/Loss'] = taxes['Long_Term_Gains'].map('${:,.2f}'.format).astype(str)
        taxes['Long Term Tax'] = taxes['Long_Term_Tax'].map('${:,.2f}'.format).astype(str)
        taxes['Short Term Gains/Loss'] = taxes['Short_Term_Gains'].map('${:,.2f}'.format).astype(str)
        taxes['Short Term Tax'] = taxes['Short_Term_Tax'].map('${:,.2f}'.format).astype(str)
        taxes['Total Estimate'] = taxes['Total_Estimate'].map('${:,.2f}'.format).astype(str)
        taxes = taxes[['Tax Year','Long Term Gains/Loss', 'Long Term Tax', 'Short Term Gains/Loss', 'Short Term Tax', 'Total Estimate']]

        filelist = os.listdir(uploads)

        return render_template('./Reports.html',
                               tables=[txn_history.to_html(classes='table table-hover table-striped'),
                                       taxes.to_html(classes='table table-hover table-striped')],list=filelist,
                               titles=['Estimated Taxes', 'Transaction History'], data=taxoptions, taxyears=taxyearoptions)
    except Exception as e:
        print(e)
    finally:
        session.close()

@app.route('/download', methods=['GET'])
def download():
    try:
        return send_file('{}2017_8949.csv'.format(downloads), as_attachment=True)
    except Exception as e:
        print(e)

@app.route('/download2', methods=['GET'])
def download2():
    try:
        return send_file('{}f1099k_2018.csv'.format(downloads), as_attachment=True)
    except Exception as e:
        print(e)


@app.route("/sendfile", methods=["POST"])
def send_file2():
    fileob = request.files["file2upload"]
    filename = secure_filename(fileob.filename)
    save_path = "{}/{}".format(app.config["UPLOAD_FOLDER"], filename)
    fileob.save(save_path)

    # open and close to update the access time.
    with open(save_path, "r") as f:
        pass

    return "successful_upload"

@app.route("/filenames", methods=["GET"])
def get_filenames():
    filenames = os.listdir(uploads)

    # modify_time_sort = lambda f: os.stat("uploads/{}".format(f)).st_atime

    def modify_time_sort(file_name):
        file_path = "{}{}".format(uploads,file_name)
        file_stats = os.stat(file_path)
        last_access_time = file_stats.st_atime
        return last_access_time

    filenames = sorted(filenames, key=modify_time_sort)
    return_dict = dict(filenames=filenames)
    return jsonify(return_dict)

@app.route("/delete_all", methods=["POST"])
def delete_all():
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        try:
            trans = session.query(Transactions).all()
            for row in trans:
                session.delete(row)
                session.commit()
        except Exception as e:
            print(e)

        try:
            taxes = session.query(Taxes).all()
            for trow in taxes:
                session.delete(trow)
                session.commit()
        except Exception as e:
            print(e)
    except Exception as e:
        print(e)
    finally:
        session.close()

    try:
        for f in os.listdir(uploads):
            try:
                path = os.path.join(uploads,f)
                if os.path.isfile(path):
                    os.remove(path)
            except Exception as e:
                print(e)
    except Exception as e:
        print(e)

    return redirect(url_for('reports'))

def create_irs_form(session,taxYear=2017):
    newFileName = '{}8929_2017_test.pdf'.format(taxreport_base)
    x = PdfFileReader(open('{}f8949_template.pdf'.format(taxreport_base),'rb'))
    if "/AcroForm" in x.trailer["/Root"]:
        x.trailer["/Root"]["/AcroForm"].update(
            {NameObject("/NeedAppearances"): BooleanObject(True)}
        )

    output = PdfFileWriter()
    if "/AcroForm" in output._root_object:
        output._root_object["/AcroForm"].update(
            {NameObject("/NeedAppearances"): BooleanObject(True)}
        )
    descr_index =3
    dacq_index=4
    dsold_index=5
    proceeds_index=6
    cost_index=7
    codes_index=8
    adjust_index=9
    gainloss_index=10
    page_index =0
    page_header_index=1
    for row in session.query(Transactions).filter(Transactions.Action == 'SELL'):
        y = datetime.strptime(row.Date, '%m/%d/%Y%H:%M:%S').year
        term = ''
        if y >= taxYear:
            page_index = 0
            page_header_index=1
        else:
            page_index = 1
            page_header_index=2

        gainloss = 0.0
        if row.Action == 'SELL':
            gainloss = row.Price + row.Cost
        fields =({'f'+str(page_header_index)+'_'+str(descr_index)+'[0]': str(row.Volume) + ' ' + row.Coin,  #Description
                  'f'+str(page_header_index)+'_'+str(dacq_index)+'[0]': str(row.Date),  #Date Acquired
                  'f'+str(page_header_index)+'_'+str(dsold_index)+'[0]': str(row.DateSold),  #Date Sold (c)
                  'f'+str(page_header_index)+'_'+str(proceeds_index)+'[0]': str(row.Price),  #Proceeds (d)
                  'f'+str(page_header_index)+'_'+str(cost_index)+'[0]': str(row.Cost),  #Cost Basis(e)
                  'f'+str(page_header_index)+'_'+str(codes_index)+'[0]': '0',  # codes
                  'f'+str(page_header_index)+'_'+str(adjust_index)+'[0]': '0',  # adjust
                  'f'+str(page_header_index)+'_'+str(gainloss_index)+'[0]': str(gainloss),  #Gain or loss(h)
                            })
        print('Fields')
        print(fields)
        page = x.getPage(page_index)
        output.addPage(page)
        output.updatePageFormFieldValues(page,fields)
        descr_index += 8
        dacq_index += 8
        dsold_index += 8
        proceeds_index += 8
        cost_index  += 8
        codes_index += 8
        adjust_index += 8
        gainloss_index += 8
    newObject = open(newFileName,'wb')
    output.write(newObject)
    newObject.close()

def create_irs_csv(session,taxYear=2017):
    with open('{}2017_8949.csv'.format(downloads), 'w', newline='') as csvData:
        fieldnames = ['Description (a)', 'Date Acquired(b)', 'Date Sold (c)', 'Proceeds (d)', 'Cost Basis(e)',
                      'Adjustment Code (f)', 'Adjustment amount(g)', 'Gain or loss(h)', 'Term']
        csvWriter = csv.DictWriter(csvData, fieldnames=fieldnames)
        csvWriter.writeheader()
        for row in session.query(Transactions).filter(Transactions.Action == 'SELL'):
            y = datetime.strptime(row.Date, '%m/%d/%Y%H:%M:%S').year
            term = ''
            if y >= taxYear:
                term = 'Short-Term'
            else:
                term = 'Long-Term'

            gainloss = 0.0
            if row.Action == 'SELL':
                gainloss = row.Price + row.Cost
            csvWriter.writerow({'Description (a)': str(row.Volume) + row.Coin,
                                'Date Acquired(b)': str(row.Date),
                                'Date Sold (c)': str(row.DateSold),
                                'Proceeds (d)': str(row.Price),
                                'Cost Basis(e)': str(row.Cost),
                                'Gain or loss(h)': str(gainloss),
                                'Term': term})

def create_irs_1099k_csv(sourcefile, destination):
    try:
        with open(sourcefile, 'rb') as pdf:
            input = PdfFileReader(pdf)

            # get the data from page 3 (index 2)
            page = 3
            pindex = page - 1
            page = input.getPage(pindex)

            d = input.getFormTextFields()
            print(input.getFormTextFields())
            filer = d['f2_1[0]']
            payee = d['f2_2[0]']
            gross_amt = float(d['f2_9[0]'])
            cards_not_present = int(d['f2_10[0]'])
            payment_transactions = int(d['f2_12[0]'])
            fed_income_tax_held = float(d['f2_13[0]'])
            state_income_tax_held_1 = float(d['f2_30[0]'])
            state_income_tax_held_2 = float(d['f2_31[0]'])
            state_income_total = state_income_tax_held_1 + state_income_tax_held_2
            net = gross_amt - fed_income_tax_held - state_income_total

        with open('{}f1099k_2018.csv'.format(destination), 'w', newline='') as csvData:
            fieldnames = ['Filer','Payee','Gross Amount', 'Cards Not Present', 'Payments', 'Federal Income Tax With Held',
                          'State Income Tax With Held', 'Net']
            csvWriter = csv.DictWriter(csvData, fieldnames=fieldnames)
            csvWriter.writeheader()
            row = {fieldnames[0]: filer,
                   fieldnames[1]: payee,
                   fieldnames[2]: gross_amt,
                   fieldnames[3]: cards_not_present,
                   fieldnames[4]: payment_transactions,
                   fieldnames[5]: fed_income_tax_held,
                   fieldnames[6]: state_income_total,
                   fieldnames[7]: net}
            csvWriter.writerow(row)
    except Exception as e:
        print(e)

#FIFO calculation
def calculate_gl_estimatedtaxes(session, current_tax_year=2018, method='FIFO'):
    shortTermGains = 0
    shortTermEstTaxes = 0
    longTermGains = 0
    longTermEstTaxes = 0

    trades = []
    #Handle short term for the current tax year
    for row in session.query(Transactions).filter(Transactions.Action == "BUY"):
        trade = Trade(row.Date, row.Volume, row.Price)
        trades.append(trade)

    for row in session.query(Transactions).filter(Transactions.Action == "SELL"):
        date_acq_year = datetime.strptime(row.Date, '%m/%d/%Y%H:%M:%S').year
        date_sold_year = datetime.strptime(row.DateSold, '%m/%d/%Y%H:%M:%S').year
        if date_acq_year == current_tax_year and date_sold_year == current_tax_year:
            # negatives will be equivalent to a sell
            row.Volume = -row.Volume
            trade = Trade(row.DateSold, row.Volume, row.Price)
            trades.append(trade)

    if trades is not None:
        b = Isin('bond', 1, trades, method)
        if method == 'FIFO':
            fifotransactions = FifoAccount(b)
            print(fifotransactions)

            shortTermGains = fifotransactions.get_pnl()
            shortTermEstTaxes = shortTermGains * .28
        elif method == 'LIFO':
            lifotransactions = LifoAccount(b)
            print(lifotransactions)

            shortTermGains = lifotransactions.get_pnl()
            shortTermEstTaxes = shortTermGains * .28

    #refactor later
    #Calculate long term gains if they exist

    trades = []
    # Handle long term for the current tax year
    for row in session.query(Transactions).filter(Transactions.Action == "BUY"):
        trade = Trade(row.Date, row.Volume, row.Price)
        trades.append(trade)

    for row in session.query(Transactions).filter(Transactions.Action == "SELL"):
        date_acq_year = datetime.strptime(row.Date, '%m/%d/%Y%H:%M:%S').year
        date_sold_year = datetime.strptime(row.DateSold, '%m/%d/%Y%H:%M:%S').year

        if date_acq_year < current_tax_year and date_sold_year == current_tax_year:
            # negatives will be equivalent to a sell
            row.Volume = -row.Volume
            trade = Trade(row.DateSold, row.Volume, row.Price)
            trades.append(trade)

    if trades is not None:
        b = Isin('bond', 1, trades, method)
        if method == 'FIFO':
            fifotransactions = FifoAccount(b)
            print(fifotransactions)

            longTermGains = fifotransactions.get_pnl()
            longTermEstTaxes = longTermGains * .15
        elif method == 'LIFO':
            lifotransactions = LifoAccount(b)
            print(lifotransactions)

            longTermGains = lifotransactions.get_pnl()
            longTermEstTaxes = longTermGains * .15

    return shortTermGains, shortTermEstTaxes, longTermGains, longTermEstTaxes

def create_directories():
    try:
        try:
            dir = os.path.dirname(taxreport_base)
            if not os.path.exists(dir):
                os.makedirs(dir)
        except Exception as e:
            print(e)

        try:
            dir = os.path.dirname(uploads)
            if not os.path.exists(dir):
                os.makedirs(dir)
        except Exception as e:
            print(e)

        try:
            dir = os.path.dirname(downloads)
            if not os.path.exists(dir):
                os.makedirs(dir)
        except Exception as e:
            print(e)
    except Exception as e:
        print(e)


if __name__ == '__main__':
    create_directories()
    socketio.run(app, host='127.0.0.1', port=5000, debug=False)
