import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, Alert, View, TextInput, Image, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import { colors } from './../../styles';
import OrangeButton from '../../components/buttons/OrangeButton';
import SelectDropdown from 'react-native-select-dropdown';
import { APP_NAME } from './../../constants';

const statuses = [
	{id: 0, name: 'Не юрист'},
	{id: 1, name: 'Инхаус'},
	{id: 2, name: 'Консалтинг'},
	{id: 3, name: 'Арбитражный управляющий'},
];

const ProfileScreen = ({userProfile, editProfile, route}) => {

	const navigation = useNavigation();
	const [lastname, setLastname] = React.useState('');
	const [firstname, setFirstname] = React.useState('');
	const [email, setEmail] = React.useState('');
	const [status, setStatus] = React.useState(-1);

	useEffect(() => {
		if (userProfile) {
			setLastname(userProfile.last_name);
			setFirstname(userProfile.first_name);
			setEmail(userProfile.email);
			let st = -1;
			for (let i = 0; i < statuses.length; i++) {
				if (statuses[i].id == userProfile.type) {
					st = parseInt(userProfile.type);
					break;
				}
			}
			console.warn(st);
			setStatus(st);
		} else {
			setLastname('');
			setFirstname();
			setEmail();
			setStatus(-1);
		}
	}, []);

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
        }}>
			<TextInput
				style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					height: Common.getLengthByIPhone7(44),
					borderRadius: Common.getLengthByIPhone7(10),
					backgroundColor: 'white',
					borderWidth: 1,
					borderColor: 'rgba(60, 60, 67, 0.18)',
					fontSize: Common.getLengthByIPhone7(17),
					lineHeight: Common.getLengthByIPhone7(22),
					letterSpacing: -0.408,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					color: colors.TEXT_COLOR,
					textAlign: 'left',
					paddingLeft: Common.getLengthByIPhone7(16),
					marginTop: Common.getLengthByIPhone7(30),
				}}
				placeholderTextColor={'rgba(66, 67, 71, 0.5)'}
				placeholder={'Фамилия'}
				contextMenuHidden={false}
				autoCorrect={false}
				returnKeyType={'next'}
				secureTextEntry={false}
				// keyboardType={'number-pad'}
				allowFontScaling={false}
				underlineColorAndroid={'transparent'}
				onSubmitEditing={() => {
					firstnameRef.focus();
				}}
				onFocus={() => {}}
				onBlur={() => {
				
				}}
				onChangeText={lastname => {
					setLastname(lastname);
				}}
				value={lastname}
			/>
			<TextInput
				style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					height: Common.getLengthByIPhone7(44),
					borderRadius: Common.getLengthByIPhone7(10),
					backgroundColor: 'white',
					borderWidth: 1,
					borderColor: 'rgba(60, 60, 67, 0.18)',
					fontSize: Common.getLengthByIPhone7(17),
					lineHeight: Common.getLengthByIPhone7(22),
					letterSpacing: -0.408,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					color: colors.TEXT_COLOR,
					textAlign: 'left',
					paddingLeft: Common.getLengthByIPhone7(16),
					marginTop: Common.getLengthByIPhone7(14),
				}}
				placeholderTextColor={'rgba(66, 67, 71, 0.5)'}
				ref={el => firstnameRef = el}
				placeholder={'Имя'}
				contextMenuHidden={false}
				autoCorrect={false}
				returnKeyType={'next'}
				secureTextEntry={false}
				// keyboardType={'number-pad'}
				allowFontScaling={false}
				underlineColorAndroid={'transparent'}
				onSubmitEditing={() => {
					emailRef.focus();
				}}
				onFocus={() => {}}
				onBlur={() => {
				
				}}
				onChangeText={firstname => {
					setFirstname(firstname);
				}}
				value={firstname}
			/>
			<View style={{
				justifyContent: 'center',
				alignItems: 'flex-end',
				marginTop: Common.getLengthByIPhone7(14),
			}}>
				<TextInput
					style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
						height: Common.getLengthByIPhone7(44),
						borderRadius: Common.getLengthByIPhone7(10),
						backgroundColor: 'white',
						borderWidth: 1,
						borderColor: 'rgba(60, 60, 67, 0.18)',
						fontSize: Common.getLengthByIPhone7(17),
						lineHeight: Common.getLengthByIPhone7(22),
						letterSpacing: -0.408,
						fontFamily: 'SFProText-Regular',
						fontWeight: 'normal',
						color: colors.TEXT_COLOR,
						textAlign: 'left',
						paddingLeft: Common.getLengthByIPhone7(16),
					}}
					placeholderTextColor={'rgba(66, 67, 71, 0.5)'}
					ref={el => emailRef = el}
					placeholder={'Email'}
					contextMenuHidden={false}
					autoCorrect={false}
					returnKeyType={'done'}
					secureTextEntry={false}
					keyboardType={'email-address'}
					allowFontScaling={false}
					underlineColorAndroid={'transparent'}
					onSubmitEditing={() => {
						// this.nextClick();
					}}
					onFocus={() => {}}
					onBlur={() => {
					
					}}
					onChangeText={email => {
						setEmail(email);
					}}
					value={email}
				/>
				<Image source={require('./../../assets/ic-letter.png')}
					style={{
						width: Common.getLengthByIPhone7(24),
						height: Common.getLengthByIPhone7(24),
						resizeMode: 'contain',
						position: 'absolute',
						right: Common.getLengthByIPhone7(10),
					}}
				/>
			</View>
			<Text style={{
				marginTop: Common.getLengthByIPhone7(23),
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: '600',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(17),
				lineHeight: Common.getLengthByIPhone7(22),
				letterSpacing: -0.408,
			}}
			allowFontScaling={false}>
				Статус
			</Text>
			<SelectDropdown
				data={statuses}
				defaultButtonText={'Выберите статус'}
				buttonStyle={{
					marginTop: Common.getLengthByIPhone7(12),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					height: Common.getLengthByIPhone7(44),
					borderRadius: Common.getLengthByIPhone7(10),
					backgroundColor: 'white',
					borderWidth: 1,
					borderColor: 'rgba(60, 60, 67, 0.18)',
				}}
				buttonTextStyle={{
					fontSize: Common.getLengthByIPhone7(17),
					lineHeight: Common.getLengthByIPhone7(22),
					letterSpacing: -0.408,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					color: status === -1 ? 'rgba(66, 67, 71, 0.5)' : colors.TEXT_COLOR,
					textAlign: 'left',
					// paddingLeft: Common.getLengthByIPhone7(16),
				}}
				renderDropdownIcon={() => {
					return (<Image source={require('./../../assets/ic-select-arrow.png')}
						style={{
							width: Common.getLengthByIPhone7(24),
							height: Common.getLengthByIPhone7(24),
							resizeMode: 'contain',
						}}
					/>);
				}}
				dropdownStyle={{
					marginTop: -2,
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					backgroundColor: 'white',
					borderColor: 'rgba(60, 60, 67, 0.18)',
					borderWidth: 1,
					borderBottomLeftRadius: Common.getLengthByIPhone7(10),
					borderBottomRightRadius: Common.getLengthByIPhone7(10),
				}}
				rowStyle={{
					borderBottomWidth: 0,
					justifyContent: 'flex-start',
				}}
				renderCustomizedRowChild={text => {
					return (<View style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
						height: Common.getLengthByIPhone7(44),
						paddingLeft: Common.getLengthByIPhone7(16),
						alignItems: 'flex-start',
						justifyContent: 'center',
					}}>
						<Text style={{
							color: 'rgba(66, 67, 71, 0.5)',
							fontFamily: 'SFProText-Regular',
							fontWeight: 'normal',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(17),
							lineHeight: Common.getLengthByIPhone7(22),
							letterSpacing: -0.408,
						}}
						allowFontScaling={false}>
							{text.name}
						</Text>
					</View>);
				}}
				dropdownOverlayColor={'transparent'}
				onSelect={(selectedItem, index) => {
					console.log(selectedItem, index)
				}}
				buttonTextAfterSelection={(selectedItem, index) => {
					// text represented after item is selected
					// if data array is an array of objects then return selectedItem.property to render after item is selected
					setStatus(selectedItem.id);
					return selectedItem.name;
				}}
				rowTextForSelection={(item, index) => {
					// text represented for each item in dropdown
					// if data array is an array of objects then return item.property to represent item in dropdown
					return item;
				}}
			/>
			<OrangeButton
				style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					marginTop: Common.getLengthByIPhone7(36),
				}}
				title={'Сохранить'}
				onPress={() => {
					if (!firstname.length) {
						Alert.alert(APP_NAME, 'Укажите имя!');
						return;
					}
					if (!lastname.length) {
						Alert.alert(APP_NAME, 'Укажите фамилию!');
						return;
					}
					if (!email.length) {
						Alert.alert(APP_NAME, 'Укажите почту!');
						return;
					}
					editProfile(firstname, lastname, email, status)
					.then(() => {
						if (route.params && route.params.from === 'login') {
							navigation.navigate('LoginIn');
						} else {
							Alert.alert(APP_NAME, 'Изменения сохранены');
						}
					})
					.catch(err => {
						Alert.alert(APP_NAME, err);
					});
				}}
			/>
		</View>
	);
};

const mstp = (state: RootState) => ({
	userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
    editProfile: (first_name, last_name, email, type) => dispatch.user.editProfile(first_name, last_name, email, type),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(ProfileScreen);
