import unittest
import PyPDF2
import csv
import pandas
from tabula import read_pdf

class DocumentTests(unittest.TestCase):
    def test_irs1099K_Export_To_CSV(self):
        #get test template
        try:
            sourcefile = "C:\\VegaIS\\Tests\\f1099k_2018_Test1.pdf"
            with open(sourcefile, 'rb') as pdf:
                input = PyPDF2.PdfFileReader(pdf)

                #get the data from page 3 (index 2)
                page = 3
                pindex = page - 1
                page = input.getPage(pindex)

                d = input.getFormTextFields()
                print(input.getFormTextFields())
                #writer = PyPDF2.PdfFileWriter()
                #writer.
                #df = read_pdf(sourcefile, output_format='json')
                #print(df)
                #self.assertNotEqual(0, df.count())
                gross_amt = float(d['f2_9[0]'])
                cards_not_present = int(d['f2_10[0]'])
                payment_transactions = int(d['f2_12[0]'])
                fed_income_tax_held = float(d['f2_13[0]'])
                state_income_tax_held_1 = float(d['f2_30[0]'])
                state_income_tax_held_2 = float(d['f2_31[0]'])
                state_income_total = state_income_tax_held_1 + state_income_tax_held_2

                self.assertNotEqual(0.0,gross_amt)

            with open('f1099k_2018.csv', 'w', newline='') as csvData:
                fieldnames = ['Gross Amount', 'Cards Not Present','Payments', 'Federal Income Tax With Held', 'State Income Tax With Held']
                csvWriter = csv.DictWriter(csvData, fieldnames=fieldnames)
                csvWriter.writeheader()
                row = {fieldnames[0]:gross_amt,
                       fieldnames[1]:cards_not_present,
                       fieldnames[2]:payment_transactions,
                       fieldnames[3]:fed_income_tax_held,
                       fieldnames[4]:state_income_total}
                csvWriter.writerow(row)
        except Exception as e:
            print(e)
