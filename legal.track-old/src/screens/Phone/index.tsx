import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, BackHandler, StatusBar, View, Alert, Linking, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Common from '../../utilities/Common';
import { colors } from './../../styles';
import OrangeButton from '../../components/buttons/OrangeButton';
import PhoneInputView from '../../components/ Phone/PhoneInputView';
import { APP_NAME } from './../../constants';
import LoadingView from '../../components/LoadingView';

const PhoneScreen = ({isRequestGoing, getCode}) => {

	const navigation = useNavigation();
	const [phone, setPhone] = React.useState('');

	useFocusEffect(
		React.useCallback(() => {
			BackHandler.addEventListener("hardwareBackPress", backButtonHandler);
			return () => {
				BackHandler.removeEventListener("hardwareBackPress", backButtonHandler);
			};
		}, [])
	);

	const backButtonHandler = () => {
		return true;
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: colors.MAIN_COLOR,
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<View style={{
				alignItems: 'center',
				justifyContent: 'center',
			}}>
				<Text style={{
					color: colors.ORANGE_COLOR,
					fontFamily: 'SFProText-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(24),
					lineHeight: Common.getLengthByIPhone7(29),
					marginBottom: Common.getLengthByIPhone7(34),
				}}
				allowFontScaling={false}>
					В<Text style={{
						color: 'white',
						fontFamily: 'SFProText-Regular',
						fontWeight: '600',
						textAlign: 'center',
						fontSize: Common.getLengthByIPhone7(24),
						lineHeight: Common.getLengthByIPhone7(29),
					}}
					allowFontScaling={false}>
						ход
					</Text>
				</Text>
				<PhoneInputView
					onChangeFormattedText={text => {
						let phone = text.replace(/[^\d.-]/g, '');
						setPhone(text);
					}}
				/>
				<OrangeButton
					style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
						marginTop: Common.getLengthByIPhone7(14),
					}}
					title={'Далее'}
					onPress={() => {
						if (phone.length) {
							let phone2 = phone.replace(/[^\d.-]/g, '');
							getCode(phone2)
							.then(() => {
								navigation.navigate('Code', {phone: phone2});
							})
							.catch(err => {
								Alert.alert(
									APP_NAME,
									"Произошла ошибка! Свяжитесь с техподдержкой проекта.",
									[
									  {
										text: "Отмена",
										onPress: () => console.log("Cancel Pressed"),
										style: "cancel",
									  },
									  { text: "Сообщить", onPress: () => {
											let url = 'http://legaltrack.ru/';
											Linking.canOpenURL(url).then(supported => {
												if (supported) {
													Linking.openURL(url);
												} else {
													console.log("Don't know how to open URI: " + this.props.url);
												}
											});
									  }}
									]
								);
							});
						} else {
							Alert.alert(APP_NAME, 'Введите номер телефона!');
						}
					}}
				/>
				<Text style={{
					color: 'white',
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(18),
					lineHeight: Common.getLengthByIPhone7(26),
					marginTop: Common.getLengthByIPhone7(20),
				}}
				allowFontScaling={false}>
					Поддержка в Телеграмм
				</Text>
				<Text style={{
					color: colors.ORANGE_COLOR,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(16),
					// lineHeight: Common.getLengthByIPhone7(16),
					textDecorationLine: 'underline',
				}}
				allowFontScaling={false}
				onPress={() => {
					let url = 'https://t.me/legaltrack';
					Linking.canOpenURL(url).then(supported => {
						if (supported) {
							Linking.openURL(url);
						} else {
							console.log("Don't know how to open URI: " + this.props.url);
						}
					});
				}}>
					https://t.me/legaltrack
				</Text>
			</View>
			<Text style={{
				color: 'white',
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(16),
				position: 'absolute',
				bottom: Common.getLengthByIPhone7(60),
			}}
			allowFontScaling={false}>
				{`Нажимая на кнопку, вы принимаете соглашение с\n`}<Text style={{
					color: 'white',
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(16),
					textDecorationLine: 'underline',
				}}
				allowFontScaling={false}
				onPress={() => {
					let url = 'https://kazna.tech/politics';
					Linking.canOpenURL(url).then(supported => {
					if (supported) {
						Linking.openURL(url);
					} else {
						console.log("Don't know how to open URI: " + this.props.url);
					}
					});
				}}>
					политикой персональных данных
				</Text>
			</Text>
		</View>
	);
};

const mstp = (state: RootState) => ({
	userProfile: state.user.userProfile,
	isRequestGoing: state.user.isRequestGoing,
});

const mdtp = (dispatch: Dispatch) => ({
    getCode: phone => dispatch.user.getCode(phone),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(PhoneScreen);
