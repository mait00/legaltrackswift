import React, { useCallback, useEffect, useRef } from 'react';
import { Linking, View, TouchableOpacity, ScrollView, Text, Image, Share, Alert } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import { colors } from '../../styles';
import { APP_NAME } from '../../constants';
import Dialog from "react-native-dialog";
import Toast from 'react-native-simple-toast';
import Clipboard from '@react-native-clipboard/clipboard';

const CompanyScreen = ({route, getCompany, renameCase, getSubscribtions, currentCase}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);
	const [visible, setVisible] = React.useState(false);
	const [casename, setCaseName] = React.useState('');
	const [caseObj, setCaseObj] = React.useState(null);
	const [company, setCompany] = React.useState(null);

	useEffect(() => {
		// console.warn('route: ', route);
		setBody(null);
		getCompany(route.params.data.id)
		.then(data => {
			renderBody(data);
			setCompany(data);
		})
		.catch(err => {

		});
	}, []);

	const renderCase = obj => {
		console.warn('obj: ', obj);
		let date = obj.date;
		date = date.split('-');
		date = date[0] + '.' + date[1] + '.' + date[2];
		return (<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			paddingTop: Common.getLengthByIPhone7(5),
			paddingBottom: Common.getLengthByIPhone7(5),
		}}
		onPress={() => {
			if (route.name === 'Company2') {
				navigation.navigate('Case2', {data: {id: obj.id, from: 'company'}});
			} else {
				navigation.navigate('Case', {data: {id: obj.id, from: 'company'}});
			}
		}}>
			<View style={{
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'flex-start',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
			}}>
				<Image
					source={require('./../../assets/ic-calendar.png')}
					style={{
						resizeMode: 'contain',
						width: Common.getLengthByIPhone7(24),
						height: Common.getLengthByIPhone7(24),
					}}
				/>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{date}
				</Text>
				<Text style={{
					marginLeft: Common.getLengthByIPhone7(5),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{obj.case}
				</Text>
			</View>
			<Text style={{
				marginLeft: Common.getLengthByIPhone7(5),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(14),
			}}
			allowFontScaling={false}>
				{obj.istec} - {obj.otvetchik}
			</Text>
		</TouchableOpacity>);
	}

	const renderBody = data => {

		setCaseObj(data);
		setCaseName(data.name ? data.name : data.value);

		let cases = [];

		console.warn('data.cases: ', data.cases);
		for (let i = 0; i < data.cases.length; i++) {
			cases.push(renderCase(data.cases[i]));
		}

		setBody(<ScrollView style={{
			width: Common.getLengthByIPhone7(0),
			// marginBottom: Common.getLengthByIPhone7(50),
			flex: 1,
		}}
		contentContainerStyle={{
			alignItems: 'center',
			justifyContent: 'flex-start',
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(12),
				paddingLeft: Common.getLengthByIPhone7(16),
				paddingRight: Common.getLengthByIPhone7(16),
				paddingBottom: Common.getLengthByIPhone7(16),
				backgroundColor: colors.MAIN_COLOR,
			}}>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
					borderBottomColor: 'white',
					borderBottomWidth: 1,
					// flexDirection: 'row',
					alignItems: 'flex-start',
					justifyContent: 'space-between',
					marginTop: Common.getLengthByIPhone7(5),
					marginBottom: Common.getLengthByIPhone7(5),
				}}>
					<Text style={{
						maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
						color: 'white',
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(20),
					}}
					allowFontScaling={false}>
						{data.name ? data.name : data.value}
					</Text>
					<Text style={{
						marginTop: Common.getLengthByIPhone7(5),
						marginBottom: Common.getLengthByIPhone7(8),
						color: 'white',
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(10),
					}}
					allowFontScaling={false}>
						{Common.getDigitStr(data.cases.length, {d1: ' судебное дело', d2_d4: ' судебных дела', d5_d10: ' судебных дел', d11_d19: ' судебных дел'})}
					</Text>
				</View>
				{renderRow('ОГРН', data.data.ogrn)}
				{renderRow('ИНН/КПП', data.data.inn)}
				<Text style={{
					marginTop: Common.getLengthByIPhone7(6),
					color: 'white',
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(14),
					// lineHeight: Common.getLengthByIPhone7(12),
				}}
				onPress={() => {
					// console.warn('company: ', route.params.data);
					if (route.name === 'Company2') {
						navigation.navigate('CompanyInfo2', {data: route.params.data});
					} else {
						navigation.navigate('CompanyInfo', {data: route.params.data});
					}
				}}
				allowFontScaling={false}>
					Подробнее
				</Text>
			</View>
			{cases.length ? (<View style={{
				marginTop: Common.getLengthByIPhone7(20),
				marginBottom: Common.getLengthByIPhone7(10),
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				flexDirection: 'row',
				alignItems: 'center',
			}}>
				<Image
					source={require('./../../assets/ic-events.png')}
					style={{
						resizeMode: 'contain',
						width: Common.getLengthByIPhone7(16),
						height: Common.getLengthByIPhone7(16),
					}}
				/>
				<Text style={{
					marginLeft: Common.getLengthByIPhone7(7),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(20),
					lineHeight: Common.getLengthByIPhone7(28),
				}}
				allowFontScaling={false}>
					Арбитражные дела
				</Text>
			</View>) : (<View style={{
				marginTop: Common.getLengthByIPhone7(20),
				marginBottom: Common.getLengthByIPhone7(10),
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				alignItems: 'center',
				justifyContent: 'center',
				flex: 1,
			}}>
				<Text style={{
					marginLeft: Common.getLengthByIPhone7(7),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(16),
					// lineHeight: Common.getLengthByIPhone7(28),
				}}
				allowFontScaling={false}>
					Выполняется поиск судебных дел по компании
				</Text>
			</View>)}
			{cases}
		</ScrollView>);
	}

	renderButton = (title, icon, style, action) => {
		return (<TouchableOpacity style={[{
			alignItems: 'center',
		}, style]}
		onPress={() => {
			action();
		}}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(36),
					height: Common.getLengthByIPhone7(36),
					// tintColor: 'white',
					resizeMode: 'contain',
				}}
			/>
			<Text style={{
				marginTop: Common.getLengthByIPhone7(6),
				color: colors.ORANGE_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'normal',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(11),
				lineHeight: Common.getLengthByIPhone7(12),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
		</TouchableOpacity>);
	}

	renderRow = (title, value) => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
			height: Common.getLengthByIPhone7(40),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'space-between',
			paddingTop: Common.getLengthByIPhone7(4),
			paddingBottom: Common.getLengthByIPhone7(4),
		}}>
			<Text style={{
				// width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72)) / 2,
				color: 'white',
				opacity: 0.39,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(14),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
			<View style={{
				flexDirection: 'row',
				alignItems: 'center',
			}}>
				<Text style={{
					// width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72)) / 2,
					color: 'white',
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{value}
				</Text>
				<TouchableOpacity style={{
					marginLeft: Common.getLengthByIPhone7(5),
				}}
				onPress={() => {
					Clipboard.setString(value);
                    Toast.show(title + ' скопирован');
				}}>
					<Image source={require('./../../assets/ic-copy.png')} style={{
						width: Common.getLengthByIPhone7(20),
						height: Common.getLengthByIPhone7(20),
						resizeMode: 'contain',
						tintColor: 'white'
					}}/>
				</TouchableOpacity>
			</View>
		</View>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			{body}
			<Dialog.Container visible={visible}>
				<Dialog.Title>Переименовать компанию</Dialog.Title>
				<Dialog.Input value={casename} onChangeText={text => setCaseName(text)} />
				<Dialog.Button label="Отмена" onPress={() => {
					setVisible(false);
				}} />
				<Dialog.Button label="Сохранить" onPress={() => {
					if (casename.length) {
						renameCase({id: caseObj.id, name: casename})
						.then(() => {
							getSubscribtions();
							setVisible(false);
							getCompany(route.params.data.id)
							.then(data => {
								renderBody(data);
							})
							.catch(err => {

							});
						})
						.catch(err => {
							setVisible(false);
							Alert.alert(APP_NAME, err);
						});
					} else {
						Alert.alert(APP_NAME, 'Укажите название!');
					}
				}} />
			</Dialog.Container>
		</View>
	);
};

const mstp = (state: RootState) => ({
	currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    getCompany: payload => dispatch.all.getCompany(payload),
	// renameCase: payload => dispatch.all.renameCase(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
});

export default connect(mstp, mdtp)(CompanyScreen);
