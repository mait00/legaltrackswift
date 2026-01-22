import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, Platform, StatusBar, View, TextInput, Linking, Text, Alert, KeyboardAvoidingView } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import { colors } from './../../styles';
import OrangeButton from '../../components/buttons/OrangeButton';
import LoadingView from '../../components/LoadingView';
import { APP_NAME } from './../../constants';

const CodeScreen = ({sendCode, getTarifs, getProfile, route}) => {

	const navigation = useNavigation();
	const [code, setCode] = React.useState('');

	return (
        <View style={{
            flex: 1,
            backgroundColor: colors.MAIN_COLOR,
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<KeyboardAvoidingView
				behavior={Platform.OS === "ios" ? "padding" : "height"}
				style={{
					flex: 1,
					backgroundColor: colors.MAIN_COLOR,
					alignItems: 'center',
					justifyContent: 'center',
				}}
			>
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
				<TextInput
					style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
						height: Common.getLengthByIPhone7(42),
						borderRadius: Common.getLengthByIPhone7(10),
						backgroundColor: 'white',
						fontSize: Common.getLengthByIPhone7(17),
						lineHeight: Common.getLengthByIPhone7(22),
						letterSpacing: -0.408,
						fontFamily: 'SFProText-Regular',
						fontWeight: 'normal',
						color: colors.TEXT_COLOR,
						textAlign: 'center',
					}}
					placeholderTextColor={'rgba(50, 38, 97, 0.6)'}
					placeholder={'СМС код'}
					contextMenuHidden={false}
					autoCorrect={false}
					autoCompleteType={'off'}
					returnKeyType={'done'}
					secureTextEntry={false}
					keyboardType={'number-pad'}
					allowFontScaling={false}
					underlineColorAndroid={'transparent'}
					onSubmitEditing={() => {
						// this.nextClick();
					}}
					onFocus={() => {}}
					onBlur={() => {
					
					}}
					onChangeText={code => {
						setCode(code);
					}}
					value={code}
				/>
				<OrangeButton
					style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
						marginTop: Common.getLengthByIPhone7(14),
					}}
					title={'Далее'}
					onPress={() => {
						if (code.length) {
							sendCode({phone: route.params.phone, code: code})
							.then(() => {
								getProfile()
								.then(profile => {
									getTarifs();
									if (profile.first_name == null) {
										navigation.navigate('Profile2', {from: 'login'});
									} else {
										navigation.navigate('LoginIn');
									}
								})
								.catch(err => {
									Alert.alert(APP_NAME, err);
								});
							})
							.catch(err => {
								Alert.alert(APP_NAME, err);
							});
						} else {
							Alert.alert(APP_NAME, 'Введите код СМС!');
						}
					}}
				/>
			</View>
			</KeyboardAvoidingView>
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
	isRequestGoing: state.user.isRequestGoing,
	userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
    sendCode: payload => dispatch.user.sendCode(payload),
	getProfile: () => dispatch.user.getProfile(),
	getTarifs: () => dispatch.user.getTarifs(),
});

export default connect(mstp, mdtp)(CodeScreen);
