import csv
import os
from datetime import datetime

import pandas as pd
from PyPDF2 import PdfFileReader, PdfFileWriter
from PyPDF2.generic import NameObject, BooleanObject
from flask import Flask, render_template, send_file, jsonify
from flask import request
from flask_socketio import SocketIO
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from werkzeug.utils import secure_filename
from Config.config import reports_db, uploads, taxreport_base

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
    directory =  uploads
    for f in os.listdir(directory):
        try:
            with open(os.path.join(directory, f)) as csvDataFile:
                csvReader = csv.DictReader(csvDataFile)
                for row in csvReader:
                    try:
                        txn = Transactions()
                        txn.Date = row['Date']
                        txn.DateSold = row['DateSold']
                        txn.Exchange = row['Exchange']
                        txn.Action = row['Action']
                        txn.Coin = row['Coin']
                        txn.Volume = float(row['Volume'])
                        txn.Price = float(row['Price'])
                        txn.Fees = float(row['Fees'])
                        txn.Cost = row['Cost']

                        if txn.Action == 'BUY':
                            txn.Cost = (txn.Volume * txn.Price) + txn.Fees
                            txn.Cost = -txn.Cost

                        # TODO: refactor this, I was having an issue with trying to update.
                        t = session.query(Transactions).filter((Transactions.Date == txn.Date and
                                                                Transactions.Exchange == txn.Exchange and Transactions.Action == txn.Action)).first()
                        if t == None:
                            session.add(txn)
                            session.commit()
                        else:
                            currenttxn = session.query(Transactions).filter((Transactions.Date == txn.Date and
                                                                               Transactions.Exchange == txn.Exchange and Transactions.Action == txn.Action)).first()
                            session.delete(currenttxn)
                            session.commit()
                            session.add(txn)
                            session.commit()
                    except Exception as e:
                        print(e)
                        session.rollback()
        except Exception as e:
            print(e)

# Handle the transactions and estimated taxes
@app.route('/reports', methods=['GET', 'POST'])
def reports(taxyear=2017):
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
        previous_ids_for_cost_basis = []
        for currentrow in session.query(Transactions):
            y = datetime.strptime(currentrow.Date, '%m/%d/%Y%H:%M:%S').year
            if currentrow.Action == 'SELL':
                if y >= 2017:
                    taxobj.Short_Term_Gains += currentrow.Price + currentrow.Cost
                else:
                    taxobj.Long_Term_Gains += currentrow.Cost

        taxobj.Long_Term_Tax = taxobj.Long_Term_Gains * .15
        taxobj.Short_Term_Tax = taxobj.Short_Term_Gains * .28

        taxobj.Total_Estimate = taxobj.Long_Term_Tax + taxobj.Short_Term_Tax
        if count == 0:
            session.add(taxobj)
            session.commit()
        else:
            currenttaxes = session.query(Taxes).filter(Taxes.Year == 2017).first()
            session.delete(currenttaxes)
            session.commit()
            session.add(taxobj)
            session.commit()
        query = session.query(Taxes).filter(Taxes.Year == 2017)
        taxes = pd.read_sql(query.statement, session.bind, index_col=None)

        taxes['Long Term Gains/Loss'] = taxes['Long_Term_Gains'].map('${:,.2f}'.format).astype(str)
        taxes['Long Term Tax'] = taxes['Long_Term_Tax'].map('${:,.2f}'.format).astype(str)
        taxes['Short Term Gains/Loss'] = taxes['Short_Term_Gains'].map('${:,.2f}'.format).astype(str)
        taxes['Short Term Tax'] = taxes['Short_Term_Tax'].map('${:,.2f}'.format).astype(str)
        taxes['Total Estimate'] = taxes['Total_Estimate'].map('${:,.2f}'.format).astype(str)
        taxes = taxes[
            ['Long Term Gains/Loss', 'Long Term Tax', 'Short Term Gains/Loss', 'Short Term Tax', 'Total Estimate']]

        filelist = os.listdir(uploads)

        return render_template('./Reports.html',
                               tables=[txn_history.to_html(classes='table table-hover table-striped'),
                                       taxes.to_html(classes='table table-hover table-striped')],list=[filelist],
                               titles=['Estimated Taxes', 'Transaction History'])
    finally:
        session.close()

@app.route('/download', methods=['GET'])
def download():
    try:
        return send_file('{}2017_8949.csv'.format(taxreport_base), as_attachment=True)
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
    with open('2017_8949.csv', 'w', newline='') as csvData:
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

if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=5000, debug=False)
