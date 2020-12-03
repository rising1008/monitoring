# -*- coding: utf-8 -*-
import numpy as np
import csv
import json
from collections import OrderedDict
import datetime
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
formater = logging.Formatter('[%(levelname)s]: %(message)s')
sh = logging.StreamHandler()
sh.setFormatter(formater)
logger.addHandler(sh)

def main():
    
    rootDir = os.path.dirname(os.path.dirname(__file__))
    inputFilesDir = rootDir + "/input-files"
    outputFileDir = rootDir + "/output-file"
    
    # input-filesフォルダ内の全てのファイル
    inputFiles = [filename for filename in os.listdir(inputFilesDir) if not filename.startswith('.')]
    
    logger.info(str(len(inputFiles)) + "件のファイルの変換処理を開始します。")
    
    totalDataNum = 0
    totalErrorDataNum = 0
    list=[]

    for i in range(len(inputFiles)):
        with open(inputFilesDir + "/" + inputFiles[i]) as rf:
            logger.info("  " + inputFiles[i] + "の処理中..." + "(" +  str(i + 1) + "/" + str(len(inputFiles)) + "ファイル)")
            fileLineNo = 0
            reader = csv.reader(rf)
            for row in reader:
                fileLineNo += 1
                try:
                    dt = datetime.datetime.strptime(row[0][1:20], "%Y-%m-%d %H:%M:%S").replace(microsecond=0).astimezone(datetime.timezone(datetime.timedelta(hours=+9)))
                    deviceId = row[0][22:25]
                    objectId = row[1]
                    latitude = float(row[4].rstrip(")"))
                    longitude = float(row[3].lstrip("("))
                    category = ""
                    if row[1][0:3] == "Bus":
                        category = "BUS"
                    elif row[1][0:3] == "RSC":
                        category = "RSC"
                    elif row[1][0:3] == "歩行者":
                        category = "PDS"
                    elif row[1][0:3].isdecimal():
                        category = "SCT"
                    # 2系(緯度：33度、経度：131度)で座標変換を行う
                    x, z = calcXY(longitude, latitude, 33., 131.)
        
                    dic = OrderedDict()
                    dic["dateTime"] = dt.isoformat()
                    dic["unixTime"] = int(dt.timestamp())
                    dic["deviceId"] = deviceId
                    dic["objectId"] = objectId
                    dic["category"] = category
                    dic["latitude"] = latitude
                    dic["longitude"] = longitude
                    dic["z"] = z
                    dic["x"] = x
                    list.append(dic)
                    totalDataNum += 1
                except:
                    totalErrorDataNum += 1
                    logger.error("    " + str(fileLineNo) + "行目の変換に失敗しました。")
                    continue
    
    # unixTime でソート
    list = sorted(list, key=lambda x: x["unixTime"])

    # jsonファイルのアウトプット
    with open(outputFileDir + "/12c62cfb-1d46-4efe-89f3-afb617611856.json", "w") as wf:
        json.dump(list,wf,indent=2,ensure_ascii=False)
    if totalErrorDataNum > 0:
        logger.info(str(totalDataNum) + "件中 " + str(totalErrorDataNum) + "件のエラーが発生しました。")
    else:
        logger.info(str(totalDataNum) + "件のデータを処理しました。")
    logger.info("データ生成処理を終了します。")

"""
経度緯度を平面直角座標へ変換する関数
変換の計算式は、国土交通省 国土地理院の測量計算サイトを参考に実装しています。
https://vldb.gsi.go.jp/sokuchi/surveycalc/surveycalc/algorithm/bl2xy/bl2xy.htm
"""
def calcXY(phiDeg, lambdaDeg, phi0Deg, lambda0Deg):

    # 緯度経度・平面直角座標系原点をラジアンに直す
    phiRad = np.deg2rad(phiDeg)
    lambdaRad = np.deg2rad(lambdaDeg)
    phi0Rad = np.deg2rad(phi0Deg)
    lambda0Rad = np.deg2rad(lambda0Deg)

    # 補助関数
    def AArray(n):
        A0 = 1 + (n**2)/4. + (n**4)/64.
        A1 = -     (3./2)*( n - (n**3)/8. - (n**5)/64. ) 
        A2 =     (15./16)*( n**2 - (n**4)/4. )
        A3 = -   (35./48)*( n**3 - (5./16)*(n**5) )
        A4 =   (315./512)*( n**4 )
        A5 = -(693./1280)*( n**5 )
        return np.array([A0, A1, A2, A3, A4, A5])

    def alphaArray(n):
        a0 = np.nan # dummy
        a1 = (1./2)*n - (2./3)*(n**2) + (5./16)*(n**3) + (41./180)*(n**4) - (127./288)*(n**5)
        a2 = (13./48)*(n**2) - (3./5)*(n**3) + (557./1440)*(n**4) + (281./630)*(n**5)
        a3 = (61./240)*(n**3) - (103./140)*(n**4) + (15061./26880)*(n**5)
        a4 = (49561./161280)*(n**4) - (179./168)*(n**5)
        a5 = (34729./80640)*(n**5)
        return np.array([a0, a1, a2, a3, a4, a5])

    # 定数 (a, F: 世界測地系-測地基準系1980（GRS80）楕円体)
    m0 = 0.9999 
    a = 6378137.
    F = 298.257222101

    # (1) n, A_i, alpha_iの計算
    n = 1. / (2*F - 1)
    AArray = AArray(n)
    alphaArray = alphaArray(n)

    # (2), S, Aの計算
    A_ = ( (m0*a)/(1.+n) )*AArray[0] # [m]
    S_ = ( (m0*a)/(1.+n) )*( AArray[0]*phi0Rad + np.dot(AArray[1:], np.sin(2*phi0Rad*np.arange(1,6))) ) # [m]

    # (3) lambda_c, lambda_sの計算
    lambdaC = np.cos(lambdaRad - lambda0Rad)
    lambdaS = np.sin(lambdaRad - lambda0Rad)

    # (4) t, t_の計算
    t = np.sinh( np.arctanh(np.sin(phiRad)) - ((2*np.sqrt(n)) / (1+n))*np.arctanh(((2*np.sqrt(n)) / (1+n)) * np.sin(phiRad)) )
    t_ = np.sqrt(1 + t*t)

    # (5) xi", eta"の計算
    xi2  = np.arctan(t / lambdaC) # [rad]
    eta2 = np.arctanh(lambdaS / t_)

    # (6) x, yの計算
    x = A_ * (xi2 + np.sum(np.multiply(alphaArray[1:],
                                       np.multiply(np.sin(2*xi2*np.arange(1,6)),
                                                   np.cosh(2*eta2*np.arange(1,6)))))) - S_ # [m]
    y = A_ * (eta2 + np.sum(np.multiply(alphaArray[1:],
                                        np.multiply(np.cos(2*xi2*np.arange(1,6)),
                                                    np.sinh(2*eta2*np.arange(1,6)))))) # [m]
    # return
    return x, y # [m]


if __name__ == "__main__":
    main()