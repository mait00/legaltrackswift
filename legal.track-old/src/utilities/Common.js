import React from 'react';
import { Platform, Dimensions } from 'react-native';

class Common extends React.Component {

  constructor(props) {
    super(props);
  }

  isPortrait = () => {
    const dim = Dimensions.get('screen');
    return dim.height >= dim.width;
  }

  getDigitStr = (digit, strings) => {
    let noteStr = '';

    if (digit > 10 && digit < 20) {
      noteStr = digit + ' ' + strings.d11_d19;
    } else if (digit % 10 == 1) {
      noteStr = digit + ' ' + strings.d1;
    } else if (digit % 10 > 1 && digit % 10 < 5) {
      noteStr = digit + ' ' + strings.d2_d4;
    } else {
      noteStr = digit + ' ' + strings.d5_d10;
    }

    return noteStr;
  }

  getRusDate = date => {

    let dd = date.getDate();
    dd = dd < 10 ? '0' + dd : dd;

    let mm = date.getMonth() + 1;
    mm = mm < 10 ? '0' + mm : mm;

    let yyyy = date.getFullYear();

    let str = dd + '.' + mm + '.' + yyyy;

    return str;
  }

  getEngDate = date => {

    let dd = date.getDate();
    dd = dd < 10 ? '0' + dd : dd;

    let mm = date.getMonth() + 1;
    mm = mm < 10 ? '0' + mm : mm;

    let yyyy = date.getFullYear();

    let str = yyyy+ '-' + mm + '-' + dd;

    return str;
  }

  getLengthByIPhone7 = (length) => {
    if(length > 0) {
      if(this.isPortrait()) {
        return Math.round(Dimensions.get('window').width*length/375);
      } else {
        return Math.round(Dimensions.get('window').height*length/375);
      }
    } else {
      if(this.isPortrait()) {
        return Dimensions.get('window').width;
      } else {
        return Dimensions.get('window').height;
      }
    }
  }

  reformatPhone = phone => {
    phone = phone.replace(/[^\d.-]/g, '');
    if (phone.length) {
      if (phone.charAt(0) != '+') {
        phone = '+' + phone;
      }
      if (phone.charAt(1) != '7') {
        phone = phone.substring(0, 1) + '7' + phone.substring(2);
      }
      if (phone.length > 2 && phone.length < 6) {
        phone = phone.substring(0, 2) + ' (' + phone.substring(2, 5);
      } else if (phone.length >= 6 && phone.length < 9) {
        phone = phone.substring(0, 2) + " (" + phone.substring(2, 5) + ") " + phone.substring(5, 8);
      } else if (phone.length >= 9 && phone.length < 11) {
        phone = phone.substring(0, 2) + " (" + phone.substring(2, 5) + ") " + phone.substring(5, 8) + "-" + phone.substring(8, 10);
      } else if (phone.length >= 11) {
        phone = phone.substring(0, 2) + " (" + phone.substring(2, 5) +
            ') ' + phone.substring(5, 8) + "-" + phone.substring(8, 10) +
            '-' + phone.substring(10, 12);
      }
    }
    return phone;
  }

  reformatCode = code => {
    code = code.replace(/[^\d.-]/g, '');
    if (code.length) {
      if (code.length > 1 && code.length < 3) {
        code = code.substring(0, 1) + ' ' + code.substring(1, 2);
      } else if (code.length >= 2 && code.length < 4) {
        code = code.substring(0, 1) + ' ' + code.substring(1, 2) + ' ' + code.substring(2, 3);
      } else if (code.length === 4) {
        code = code.substring(0, 1) + ' ' + code.substring(1, 2) + ' ' + code.substring(2, 3) + ' ' + code.substring(3, 4);
      } else if (code.length >= 5) {
        code = code.substring(0, 1) + ' ' + code.substring(1, 2) + ' ' + code.substring(2, 3) + ' ' + code.substring(3, 4) + ' ' + code.substring(4, 5);
      }
    }
    return code;
  }

  validMail = mail => {
      return /^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()\.,;\s@\"]+\.{0,1})+([^<>()\.,;:\s@\"]{2,}|[\d\.]+))$/.test(mail);
  }
}

const common = new Common();
export default common;
