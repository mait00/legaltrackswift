import React, { useEffect } from 'react';
import {Image, Alert, TextInput, View, Text, Keyboard, TouchableOpacity, Dimensions, FlatList} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import {APP_NAME} from './../../constants';

const texts = {
	'-1': 'Номер дела или ссылка',
	'0': 'Введите номер дела',
	'1': 'Введите ссылку на дело',
	'2': 'Введите ИНН или название',
};

const AddItemView = ({casesList, buttonIndex, userProfile, setBarcodeList, setShowScanner, menuMode, setMenuMode, searchCompanies, newSubscription, getSubscribtions, setButtonIndex}) => {

	const navigation = useNavigation();
	const [search, setSearch] = React.useState('');
	const [showTable, setShowTable] = React.useState(false);
	const [companies, setRows] = React.useState([]);

	useEffect(() => {
		if (buttonIndex === 2) {
			if (search.length) {
				setShowTable(true);
				setMenuMode(true);
			} else {
				setRows([]);
				setShowTable(false);
			}
		} else {
			setRows([]);
			setShowTable(false);
		}
	}, [search]);

	useEffect(() => {
		if (!menuMode) {
			setRows([]);
			setShowTable(false);
			setSearch('');
			Keyboard.dismiss();
		}
	}, [menuMode]);

	const renderRow = (item: object, index: number) => {
		return (<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			marginTop: Common.getLengthByIPhone7(10),
			borderRadius: Common.getLengthByIPhone7(10),
			backgroundColor: 'white',
			shadowColor: 'black',
			shadowOffset: { width: 0, height: 2 },
			shadowOpacity: 0.08,
			shadowRadius: 7,
			elevation: 4,
			padding: Common.getLengthByIPhone7(13),
			alignItems: 'flex-start',
			justifyContent: 'flex-start',
		}}
		onPress={() => {
			if (!userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}
			Alert.alert(
				APP_NAME,
				"Добавить компанию " + item.data.name.full_with_opf + "?",
				[
					{
						text: "Нет",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
					},
					{ text: "Да", onPress: () => {
						newSubscription({type: 'company', value: item.data.inn, sou: false})
						.then(() => {
							setSearch('');
							getSubscribtions();
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					}}
				]
			);
		}}>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: '600',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(16),
			}}
			allowFontScaling={false}>
				{item.value}
			</Text>
			<Text style={{
				marginTop: 5,
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				opacity: 0.5,
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(16),
			}}
			allowFontScaling={false}>
				ИНН: {item.data.inn}
			</Text>
			<Text style={{
				marginTop: 2,
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				opacity: 0.5,
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(16),
			}}
			allowFontScaling={false}>
				{item.data.address.value}
			</Text>
		</TouchableOpacity>);
	}

	const nextClick = () => {
		if (search.length === 0) {
			Alert.alert(APP_NAME, 'Введите поисковую строку!');
			return;
		}
		if (buttonIndex === -1) {
			let sou = false;

			if (casesList.length > 5 && !userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Вы превысили лимит дел, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}

			if (search.indexOf('http://') !== -1 || search.indexOf('https://') !== -1) {
				sou = true;
			}

			if (sou && !userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}

			newSubscription({type: 'case', value: search, sou: sou})
			.then(() => {
				setSearch('');
				getSubscribtions();
			})
			.catch(err => {
				Alert.alert(APP_NAME, err);
			});
		} else if (buttonIndex === 0) {
			if (casesList.length > 5 && !userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Вы превысили лимит дел, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}
			newSubscription({type: 'case', value: search, sou: false})
			.then(() => {
				setSearch('');
				getSubscribtions();
			})
			.catch(err => {
				Alert.alert(APP_NAME, err);
			});
		} else if (buttonIndex === 1) {

			if (!userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}

			if (search.indexOf('http://') !== -1 || search.indexOf('https://') !== -1) {
				newSubscription({type: 'case', value: search, sou: true})
				.then(() => {
					setSearch('');
					getSubscribtions();
				})
				.catch(err => {
					Alert.alert(APP_NAME, err);
				});
			} else {
				Alert.alert(APP_NAME, 'Введите ссылку на дело!');
				return;
			}
		} else {
			if (userProfile.is_tarif_active) {
				Alert.alert(APP_NAME, 'Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения',
					[
						{
						text: "Отмена",
						onPress: () => console.log("Cancel Pressed"),
						style: "cancel"
						},
						{ text: "Тарифы", onPress: () => {
							navigation.navigate('Tarifs');
						}}
					]
				);
				return;
			}
			searchCompanies(search)
			.then(data => {
				// setSearch('');
				// getSubscribtions();
			})
			.catch(err => {
				Alert.alert(APP_NAME, err);
			});
		}
		Keyboard.dismiss();
	}

    return (
		<View style={{
			paddingBottom: Common.getLengthByIPhone7(10),
			borderBottomColor: 'rgba(50, 38, 97, 0.3)',
			borderBottomWidth: 1,
			overflow: 'visible',
			zIndex: 1000,
			alignItems: 'center',
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				// height: Common.getLengthByIPhone7(108),
				borderRadius: Common.getLengthByIPhone7(12),
				alignItems: 'flex-start',
				justifyContent: 'center',
				backgroundColor: colors.MAIN_COLOR,
				// paddingLeft: Common.getLengthByIPhone7(12),
				// paddingRight: Common.getLengthByIPhone7(12),
				padding: Common.getLengthByIPhone7(12),
			}}>
				<View style={{
					// marginTop: Common.getLengthByIPhone7(7),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
					height: Common.getLengthByIPhone7(44),
					backgroundColor: 'white',
					borderRadius: Common.getLengthByIPhone7(14),
				}}>
					<TextInput
						style={{
							width: Common.getLengthByIPhone7(0) - (buttonIndex === 0 ? Common.getLengthByIPhone7(190) : Common.getLengthByIPhone7(160)),
							height: Common.getLengthByIPhone7(44),
							borderRadius: Common.getLengthByIPhone7(14),
							backgroundColor: 'white',
							paddingLeft: Common.getLengthByIPhone7(10),
						}}
						clearButtonMode={'while-editing'}
						allowFontScaling={false}
						contextMenuHidden={false}
						spellCheck={true}
						autoCorrect={false}
						placeholder={texts[buttonIndex]}
						placeholderTextColor={'rgba(50, 38, 97, 0.6)'}
						autoCompleteType={'off'}
						// inputAccessoryViewID={this.props.inputAccessoryViewID}
						multiline={false}
						numberOfLines={1}
						returnKeyType={'search'}
						secureTextEntry={false}
						autoCapitalize={'none'}
						underlineColorAndroid={'transparent'}
						onSubmitEditing={() => {
							nextClick();
						}}
						// ref={el => this.textInputRef = el}
						onFocus={() => {
							
						}}
						onBlur={() => {
							
						}}
						onChangeText={(text) => {
							setSearch(text);
							if (buttonIndex === 2) {
								if (text.length > 2) {
									searchCompanies(text)
									.then(data => {
										setRows(data);
										// setSearch('');
										// getSubscribtions();
									})
									.catch(err => {
										Alert.alert(APP_NAME, err);
									});
								}
							}
						}}
						value={search}
					/>
					<View style={{
						height: Common.getLengthByIPhone7(44),
						position: 'absolute',
						top: 0,
						right: 0,
						flexDirection: 'row',
						alignItems: 'center',
						justifyContent: 'flex-end',
						paddingRight: Common.getLengthByIPhone7(4),
					}}>
						{buttonIndex === 0 ? (<TouchableOpacity style={{
							width: Common.getLengthByIPhone7(36),
							height: Common.getLengthByIPhone7(36),
							alignItems: 'center',
							justifyContent: 'center',
						}}
						onPress={() => {
							setBarcodeList(null);
							setShowScanner(true);
						}}>
							<Image source={require('./../../assets/ic-qrcode.png')}
								style={{
									width: Common.getLengthByIPhone7(30),
									height: Common.getLengthByIPhone7(30),
									resizeMode: 'contain',
								}}
							/>
						</TouchableOpacity>) : null}
						<TouchableOpacity style={{
							width: Common.getLengthByIPhone7(81),
							height: Common.getLengthByIPhone7(38),
							borderRadius: Common.getLengthByIPhone7(10),
							alignItems: 'center',
							justifyContent: 'center',
							backgroundColor: colors.ORANGE_COLOR,
						}}
						onPress={() => {
							nextClick();
						}}>
							<Text style={{
								color: 'white',
								fontFamily: 'SFProText-Regular',
								fontWeight: 'bold',
								textAlign: 'left',
								fontSize: Common.getLengthByIPhone7(12),
								lineHeight: Common.getLengthByIPhone7(22),
							}}
							allowFontScaling={false}>
								{buttonIndex === 2 ? 'Найти' : 'Добавить'}
							</Text>
						</TouchableOpacity>
					</View>
				</View>
			</View>
			{showTable ? (<View style={{
				zIndex: 100,
				position: 'absolute',
				left: -Common.getLengthByIPhone7(20),
				bottom: Common.getLengthByIPhone7(126),
				width: Common.getLengthByIPhone7(0),
				height: Common.getLengthByIPhone7(135),
				paddingRight: Common.getLengthByIPhone7(20),
				backgroundColor: 'white',
				alignItems: 'flex-end',
				justifyContent: 'flex-start',
			}}>
				<TouchableOpacity style={{
					width: Common.getLengthByIPhone7(46),
					height: Common.getLengthByIPhone7(46),
					borderRadius: Common.getLengthByIPhone7(23),
					backgroundColor: 'white',
					alignItems: 'center',
					justifyContent: 'center',
					shadowColor: 'black',
					shadowOffset: { width: 0, height: 2 },
					shadowOpacity: 0.15,
					shadowRadius: 7,
					elevation: 4,
				}}
				onPress={() => {
					setSearch('');
					Keyboard.dismiss();
				}}>
					<Image source={require('./../../assets/ic-menu-cancel.png')}
						style={{
							width: Common.getLengthByIPhone7(17),
							height: Common.getLengthByIPhone7(17),
							resizeMode: 'contain',
						}}
					/>
				</TouchableOpacity>
			</View>) : null}
			{showTable ? (<View style={{
				zIndex: 1000,
				// position: 'absolute',
				marginLeft: 0,//Common.getLengthByIPhone7(20),
				// top: Common.getLengthByIPhone7(109),
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				height: Dimensions.get('screen').height - Common.getLengthByIPhone7(360),
				paddingRight: Common.getLengthByIPhone7(20),
				backgroundColor: 'white',
				alignItems: 'center',
				justifyContent: 'flex-start',
			}}>
				<FlatList
					style={{
						width: Common.getLengthByIPhone7(0),
						flex: 1,
						backgroundColor: 'transparent',
						width: Common.getLengthByIPhone7(0),
						marginLeft: Common.getLengthByIPhone7(20),
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}
					bounces={true}
					removeClippedSubviews={false}
					scrollEventThrottle={16}
					data={companies}
					extraData={companies}
					keyExtractor={(item, index) => index.toString()}
					renderItem={({item, index}) => renderRow(item, index)}
				/>
			</View>) : null}
		</View>
	);
};

const mstp = (state: RootState) => ({
	buttonIndex: state.buttons.buttonIndex,
	menuMode: state.buttons.menuMode,
	userProfile: state.user.userProfile,
	casesList: state.all.casesList,
});

const mdtp = (dispatch: Dispatch) => ({
	setButtonIndex: payload => dispatch.buttons.setButtonIndex(payload),
	setShowScanner: payload => dispatch.buttons.setShowScanner(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
	newSubscription: payload => dispatch.all.newSubscription(payload),
	searchCompanies: payload => dispatch.all.searchCompanies(payload),
	setMenuMode: payload => dispatch.buttons.setMenuMode(payload),
	setBarcodeList: payload => dispatch.all.setBarcodeList(payload),
});

export default connect(mstp, mdtp)(AddItemView);