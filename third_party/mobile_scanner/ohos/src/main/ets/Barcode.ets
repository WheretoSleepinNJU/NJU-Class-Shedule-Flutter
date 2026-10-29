/*
* Copyright (c) 2023 Shenzhen Kaihong Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { scanCore } from '@kit.ScanKit';
import { Point } from '@ohos.UiTest';

export enum BarcodeFormat {
  /// A barcode format that represents all unknown formats.
  unknown = -1,

  /// A barcode format that represents all known formats.
  all = 0,

  /// Barcode format constant for Code 128.
  code128 = 1,

  /// Barcode format constant for Code 39.
  code39 = 2,

  /// Barcode format constant for Code 93.
  code93 = 4,

  /// Barcode format constant for Codabar.
  codabar = 8,

  /// Barcode format constant for Data Matrix.
  dataMatrix = 16,

  /// Barcode format constant for EAN-13.
  ean13 = 32,

  /// Barcode format constant for EAN-8.
  ean8 = 64,

  /// Barcode format constant for ITF (Interleaved Two-of-Five).
  itf = 128,

  /// Barcode format constant for QR Codes.
  qrCode = 256,

  /// Barcode format constant for UPC-A.
  upcA = 512,

  /// Barcode format constant for UPC-E.
  upcE = 1024,

  /// Barcode format constant for PDF-417.
  pdf417 = 2048,

  /// Barcode format constant for AZTEC.
  aztec = 4096
}

export enum BarcodeType {
  /// An unknown barcode type.
  unknown = 0,

  /// Barcode value type constant for contact information.
  contactInfo = 1,

  /// Barcode value type constant for email message details.
  email = 2,

  /// Barcode value type constant for ISBNs.
  isbn = 3,

  /// Barcode value type constant for phone numbers.
  phone = 4,

  /// Barcode value type constant for product codes.
  product = 5,

  /// Barcode value type constant for SMS details.
  sms = 6,

  /// Barcode value type constant for plain text.
  text = 7,

  /// Barcode value type constant for URLs or bookmarks.
  url = 8,

  /// Barcode value type constant for WiFi access point details.
  wifi = 9,

  /// Barcode value type constant for geographic coordinates.
  geo = 10,

  /// Barcode value type constant for calendar events.
  calendarEvent = 11,

  /// Barcode value type constant for driver license data.
  driverLicense = 12
}

export class Barcode {
  displayValue: string = '';
  rawValue: string = '';
  format: BarcodeFormat = BarcodeFormat.unknown;
  type: BarcodeType = BarcodeType.unknown;
  corners: Array<Point> = []
  size?:ESObject

  static convertScanType(value:scanCore.ScanType):BarcodeFormat {
    let format = BarcodeFormat.unknown

    switch(value) {
      case scanCore.ScanType.AZTEC_CODE:
        format = BarcodeFormat.aztec
        break
      case scanCore.ScanType.CODABAR_CODE:
        format = BarcodeFormat.codabar
        break
      case scanCore.ScanType.CODE39_CODE:
        format = BarcodeFormat.code39
        break
      case scanCore.ScanType.CODE93_CODE:
        format = BarcodeFormat.code93
        break
      case scanCore.ScanType.CODE128_CODE:
        format = BarcodeFormat.code128
        break
      case scanCore.ScanType.DATAMATRIX_CODE:
        format = BarcodeFormat.dataMatrix
        break
      case scanCore.ScanType.EAN8_CODE:
        format = BarcodeFormat.ean8
        break
      case scanCore.ScanType.EAN13_CODE:
        format = BarcodeFormat.ean13
        break
      case scanCore.ScanType.ITF14_CODE:
        format = BarcodeFormat.itf
        break
      case scanCore.ScanType.PDF417_CODE:
        format = BarcodeFormat.pdf417
        break
      case scanCore.ScanType.QR_CODE:
        format = BarcodeFormat.qrCode
        break
      case scanCore.ScanType.UPC_A_CODE:
        format = BarcodeFormat.upcA
        break
      case scanCore.ScanType.UPC_E_CODE:
        format = BarcodeFormat.upcE
        break
    }

    return format
  }

  static convertToScanType(value:BarcodeFormat): scanCore.ScanType{
    let type = scanCore.ScanType.FORMAT_UNKNOWN

    switch(value) {
      case BarcodeFormat.aztec:
        type = scanCore.ScanType.AZTEC_CODE
        break
      case BarcodeFormat.codabar:
        type = scanCore.ScanType.CODABAR_CODE
        break
      case BarcodeFormat.code39:
        type = scanCore.ScanType.CODE39_CODE
        break
      case BarcodeFormat.code93:
        type = scanCore.ScanType.CODE93_CODE
        break
      case BarcodeFormat.code128:
        type = scanCore.ScanType.CODE128_CODE
        break
      case BarcodeFormat.dataMatrix:
        type = scanCore.ScanType.DATAMATRIX_CODE
        break
      case BarcodeFormat.ean8:
        type = scanCore.ScanType.EAN8_CODE
        break
      case BarcodeFormat.ean13:
        type = scanCore.ScanType.EAN13_CODE
        break
      case BarcodeFormat.itf:
        type = scanCore.ScanType.ITF14_CODE
        break
      case BarcodeFormat.pdf417:
        type = scanCore.ScanType.PDF417_CODE
        break
      case  BarcodeFormat.qrCode:
        type = scanCore.ScanType.QR_CODE
        break
      case BarcodeFormat.upcA:
        type = scanCore.ScanType.UPC_A_CODE
        break
      case BarcodeFormat.upcE:
        type = scanCore.ScanType.UPC_E_CODE
        break
      case BarcodeFormat.all:
        type = scanCore.ScanType.ALL
        break
    }

    return type
  }
}