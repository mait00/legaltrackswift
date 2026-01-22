import React, { useEffect } from 'react';
import {StyleSheet, TextInput, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import PhoneInput from "react-native-phone-number-input";

const PhoneInputView = ({onChangeFormattedText}) => {

	const [phone, setPhone] = React.useState('');
	
	return (
		<PhoneInput
			placeholder={' '}
			containerStyle={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
				borderRadius: Common.getLengthByIPhone7(10),
			}}
			textContainerStyle={{
				backgroundColor: 'transparent',
				height: Common.getLengthByIPhone7(42),
				paddingVertical: 0,
				paddingHorizontal: 0,
			}}
			countryPickerButtonStyle={{
				height: Common.getLengthByIPhone7(42),
			}}
			textInputProps={{
				height: Platform.OS === 'ios' ? Common.getLengthByIPhone7(42) : Common.getLengthByIPhone7(52),
			}}
			textInputStyle={{
				color: colors.TEXT_COLOR,
				fontSize: Common.getLengthByIPhone7(17),
				lineHeight: Common.getLengthByIPhone7(22),
				letterSpacing: -0.408,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				// backgroundColor: 'red',
			}}
			codeTextStyle={{
				color: colors.TEXT_COLOR,
				fontSize: Common.getLengthByIPhone7(17),
				lineHeight: Common.getLengthByIPhone7(22),
				letterSpacing: -0.408,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
			}}
			defaultCode={'RU'}
            layout="first"
			value={phone}
			filterProps={{
				placeholder: 'Введите название страны',
			}}
			countryPickerProps={{
				translation: 'rus',
			}}
			// disabled
            onChangeText={(text) => {
				// console.warn('onChangeText: ', text);
            }}
            onChangeFormattedText={(text) => {
				// console.warn('onChangeFormattedText: ', text);
				if (onChangeFormattedText) {
					onChangeFormattedText(text);
				}
            }}
		/>
	);
};

const mstp = (state: RootState) => ({
	buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
	setButtonIndex: payload => dispatch.buttons.setButtonIndex(payload),
});

export default connect(mstp, mdtp)(PhoneInputView);