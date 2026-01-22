import React, { useCallback, useEffect, useRef } from 'react';
import { Dimensions, RefreshControl, Text, View, ScrollView, BackHandler, FlatList, Alert, TouchableOpacity } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import { parseSync } from '@babel/core';
import ButtonView from '../../components/Main/ButtonView';
import AddItemView from '../../components/Main/AddItemView';
import CaseView from '../../components/Main/CaseView';
import SouCaseView from '../../components/Main/SouCaseView';
import CompanyView from '../../components/Main/CompanyView';
import ItemModalView from '../../components/Main/ItemModalView';
import ScannerModalView from '../../components/Main/ScannerModalView';
import Dialog from "react-native-dialog";
import { APP_NAME } from '../../constants';
import OneSignal from 'react-native-onesignal';
import { StorageHelper } from '../../services';

const MainScreen = ({getSubscribtions, showScanner, userProfile, setButtonIndex, menuMode, getMessages, setPushId, newSubscription, renameCompany, renameCase, setShowItemMenu, buttonIndex, allSubscriptions, casesList, companiesList, keywordsList}) => {

	const navigation = useNavigation();
	const [rows1, setRows1] = React.useState([]);
	const [rows2, setRows2] = React.useState([]);
	const [rows3, setRows3] = React.useState([]);
	const [rows4, setRows4] = React.useState([]);
	const [refreshing, setRefreshing] = React.useState(false);
	const [selectedItem, setSelectedItem] = React.useState(null);
	const [visible, setVisible] = React.useState(false);
	const [casename, setCaseName] = React.useState('');
	const scroll = useRef(null);
	const [timer, setTimer] = React.useState(null);

	const mainFlatListRef = useRef(null);

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

	useEffect(() => {
		// getSubscribtions();
		setTimeout(() => {
			StorageHelper.getData('instruction')
			.then(text => {
				if (text && text.length) {

				} else {
					navigation.navigate('Instruction');
					StorageHelper.saveData('instruction', '1');
				}
			})
			.catch(err => {
				navigation.navigate('Instruction');
				StorageHelper.saveData('instruction', '1');
			});
		}, 15000);
		_refresh();

		/* O N E S I G N A L   S E T U P */
		OneSignal.setAppId("ea4c198c-ce69-4724-bbc4-22528e581180");
		OneSignal.setLogLevel(6, 0);
		OneSignal.setRequiresUserPrivacyConsent(false);
		OneSignal.promptForPushNotificationsWithUserResponse(response => {
		  console.warn('promptForPushNotificationsWithUserResponse: '+JSON.stringify(response));
			// this.OSLog("Prompt response:", response);
		});
	
		/* O N E S I G N A L  H A N D L E R S */
		OneSignal.setNotificationWillShowInForegroundHandler(notificationReceivedEvent => {
			getMessages();
		});
		OneSignal.setNotificationOpenedHandler(notification => {
			console.warn('setNotificationOpenedHandler: '+JSON.stringify(notification));
			getMessages();
			if (notification.notification.additionalData.type === 'company') {
				// NavigationService.navigate('Company', {data: {id: notification.notification.additionalData.id}});
				navigation.navigate('Company', {data: {id: notification.notification.additionalData.id}});
			} else if (notification.notification.additionalData.type === 'message') {
				// NavigationService.navigate('Chat');
				navigation.navigate('Chat');
			} else if (notification.notification.additionalData.type === 'case') {
				if (notification.notification.additionalData.is_sou) {
					navigation.navigate('SouCase', {data: {id: notification.notification.additionalData.id}});
				} else {
					navigation.navigate('Case', {data: {id: notification.notification.additionalData.id}});
				}
				// NavigationService.navigate('Item', {data: {id: notification.notification.additionalData.id}});
				
			} else if (notification.notification.additionalData.type === 'keyword') {
				// NavigationService.navigate('Word', {data: {id: notification.notification.additionalData.id}});
				navigation.navigate('Keyword', {data: {id: notification.notification.additionalData.id}});
			}
		});
		OneSignal.setInAppMessageClickHandler(event => {
		  console.warn('setInAppMessageClickHandler: '+JSON.stringify(event));
			// this.OSLog("OneSignal IAM clicked:", event);
		});
		OneSignal.addEmailSubscriptionObserver((event) => {
		  console.warn('addEmailSubscriptionObserver: '+JSON.stringify(event));
			// this.OSLog("OneSignal: email subscription changed: ", event);
		});
		OneSignal.addSubscriptionObserver(event => {
		  console.warn('addSubscriptionObserver: '+JSON.stringify(event));
			// this.OSLog("OneSignal: subscription changed:", event);
			// this.setState({ isSubscribed: event.to.isSubscribed})
		});
		OneSignal.addPermissionObserver(event => {
		  console.warn('addPermissionObserver: '+JSON.stringify(event));
			// this.OSLog("OneSignal: permission changed:", event);
		});
	
		OneSignal.getDeviceState()
		.then(device => {
		  console.warn('getDeviceState: '+JSON.stringify(device));
			setPushId(device.userId)
			.then(() => {
	
			})
			.catch(err => {
	
			});
		})
		.catch(err => {
	
		});
	}, []);

	useEffect(() => {
		setRows1(casesList);

		let array = [];
		for (let i = 0; i < casesList.length; i++) {
			if (casesList[i].is_sou == null || casesList[i].is_sou == false) {
				array.push(casesList[i]);
			}
		}
		setRows2(array);
		let array2 = [];
		for (let i = 0; i < casesList.length; i++) {
			if (casesList[i].is_sou) {
				array2.push(casesList[i]);
			}
		}
		setRows3(array2);
		setRows4(companiesList);
		// calcRows();

		let exist = false;
		for (let i=0;i<casesList.length;i++) {
			if (casesList[i].status === 'loading') {
				exist = true;
				break;
			}
		}

		if (exist) {
			if (timer === null) {
				setTimer(setInterval(() => {
					_refresh();
				}, 60000));
			}
		} else {
			if (timer !== null && timer !== undefined) {
				clearInterval(timer);
			}
			setTimer(null);
		}
	}, [allSubscriptions, casesList, companiesList, keywordsList]);

	useEffect(() => {
		if (buttonIndex === -1) {
			scroll.current.scrollTo({ x: 0, animated: true })
		} else if (buttonIndex === 0) {
			scroll.current.scrollTo({ x: Common.getLengthByIPhone7(0), animated: true })
		} else if (buttonIndex === 1) {
			scroll.current.scrollTo({ x: 2*Common.getLengthByIPhone7(0), animated: true })
		} else if (buttonIndex === 2) {
			scroll.current.scrollTo({ x: 3*Common.getLengthByIPhone7(0), animated: true })
		}
	}, [buttonIndex]);

	const _refresh = () => {
		
		getSubscribtions()
		.then(() => {
			setRefreshing(false);
		})
		.catch(err => {
			setRefreshing(false);
		});
	}

	const renderRow1 = (item: object, index: number) => {
		if (item.is_sou) {
			// console.warn(item);
			return (<SouCaseView
				data={item}
				index={index}
				action={() => {
					if (item.status === 'monitoring') {
						navigation.navigate('SouCase', {data: item});
					}
				}}
				onShowMenu={() => {
					setSelectedItem(item);
					setShowItemMenu(true);
				}}
			/>);
		} else {
			return (<CaseView
				data={item}
				index={index}
				action={() => {
					if (item.status === 'monitoring') {
						navigation.navigate('Case', {data: item});
					}
				}}
				onShowMenu={() => {
					setSelectedItem(item);
					setShowItemMenu(true);
				}}
			/>);
		}
    }

	const renderRow2 = (item: object, index: number) => {
		return (<CaseView
			data={item}
			index={index}
			action={() => {
				if (item.status === 'monitoring') {
					navigation.navigate('Case', {data: item});
				}
			}}
			onShowMenu={() => {
				setSelectedItem(item);
				setShowItemMenu(true);
			}}
		/>);
    }

	const renderRow3 = (item: object, index: number) => {
		return (<SouCaseView
			data={item}
			index={index}
			action={() => {
				if (item.status === 'monitoring') {
					navigation.navigate('SouCase', {data: item});
				}
			}}
			onShowMenu={() => {
				setSelectedItem(item);
				setShowItemMenu(true);
			}}
		/>);
    }

	const renderRow4 = (item: object, index: number) => {
		return (<CompanyView
			data={item}
			index={index}
			action={() => {
				if (item.status === 'monitoring') {
					navigation.navigate('Company', {data: item});
				}
			}}
			onShowMenu={() => {
				setSelectedItem(item);
				setShowItemMenu(true);
			}}
		/>);
    }

	useEffect(() => {
		_refresh();
	}, [refreshing]);

	const renderAlert = () => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			flex: 1,
			alignItems: 'center',
			justifyContent: 'center',
		}}>
			<Text style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(20),
			}}
			allowFontScaling={false}>
				Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения
			</Text>
			<TouchableOpacity style={{
				marginTop: Common.getLengthByIPhone7(20),
				width: Common.getLengthByIPhone7(150),
				height: Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(10),
				alignItems: 'center',
				justifyContent: 'center',
				backgroundColor: colors.ORANGE_COLOR,
			}}
			onPress={() => {
				navigation.navigate('Tarifs');
			}}>
				<Text style={{
					color: 'white',
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(16),
				}}
				allowFontScaling={false}>
					Тарифы
				</Text>
			</TouchableOpacity>
		</View>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
        }}>
			<ButtonView/>
			<AddItemView/>
			<ScrollView style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				// height: Common.getLengthByIPhone7(270),
			}}
			horizontal={true}
			pagingEnabled={true}
			showsHorizontalScrollIndicator={false}
			scrollEventThrottle={16}
			ref={el => scroll.current = el}
			onMomentumScrollEnd={event => {
				let page = Math.round(parseFloat(event.nativeEvent.contentOffset.x/Dimensions.get('window').width));
				// console.warn(page);
				setButtonIndex(page - 1);
			}}
			bounces={true}>
				<FlatList
					style={{
						flex: 1,
						backgroundColor: 'transparent',
						width: Common.getLengthByIPhone7(0),
						// marginBottom: 60,
						// marginTop: Common.getLengthByIPhone7(10),
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}
					// ListHeaderComponent={() => {
					// 	return ();
					// }}
					refreshControl={
						<RefreshControl
							refreshing={refreshing}
							onRefresh={() => {
								setRefreshing(true);
							}}
						/>
					}
					bounces={true}
					removeClippedSubviews={false}
					scrollEventThrottle={16}
					data={rows1}
					extraData={rows1}
					keyExtractor={(item, index) => index.toString()}
					renderItem={({item, index}) => renderRow1(item, index)}
				/>
				<FlatList
					style={{
						flex: 1,
						backgroundColor: 'transparent',
						width: Common.getLengthByIPhone7(0),
						// marginBottom: 60,
						// marginTop: Common.getLengthByIPhone7(10),
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}
					// ListHeaderComponent={() => {
					// 	return ();
					// }}
					refreshControl={
						<RefreshControl
							refreshing={refreshing}
							onRefresh={() => {
								setRefreshing(true);
							}}
						/>
					}
					bounces={true}
					removeClippedSubviews={false}
					scrollEventThrottle={16}
					data={rows2}
					extraData={rows2}
					keyExtractor={(item, index) => index.toString()}
					renderItem={({item, index}) => renderRow2(item, index)}
				/>
				{userProfile && !userProfile.is_tarif_active ? (renderAlert()) : (<FlatList
					style={{
						flex: 1,
						backgroundColor: 'transparent',
						width: Common.getLengthByIPhone7(0),
						// marginBottom: 60,
						// marginTop: Common.getLengthByIPhone7(10),
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}
					// ListHeaderComponent={() => {
					// 	return ();
					// }}
					refreshControl={
						<RefreshControl
							refreshing={refreshing}
							onRefresh={() => {
								setRefreshing(true);
							}}
						/>
					}
					bounces={true}
					removeClippedSubviews={false}
					scrollEventThrottle={16}
					data={rows3}
					extraData={rows3}
					keyExtractor={(item, index) => index.toString()}
					renderItem={({item, index}) => renderRow3(item, index)}
				/>)}
				{userProfile && !userProfile.is_tarif_active ? (renderAlert()) : (<FlatList
					style={{
						flex: 1,
						backgroundColor: 'transparent',
						width: Common.getLengthByIPhone7(0),
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}
					// ListHeaderComponent={() => {
					// 	return ();
					// }}
					refreshControl={
						<RefreshControl
							refreshing={refreshing}
							onRefresh={() => {
								setRefreshing(true);
							}}
						/>
					}
					bounces={true}
					removeClippedSubviews={false}
					scrollEventThrottle={16}
					data={rows4}
					extraData={rows4}
					keyExtractor={(item, index) => index.toString()}
					renderItem={({item, index}) => renderRow4(item, index)}
				/>)}
			</ScrollView>
			<ItemModalView
				data={selectedItem}
				onRename={() => {
					setCaseName(selectedItem.name ? selectedItem.name : selectedItem.value);
					setTimeout(() => {
						setVisible(true);
					}, 500);
				}}
			/>
			{showScanner ? (<ScannerModalView
				onScan={case_id => {
					newSubscription({type: 'case', value: case_id, sou: false})
					.then(() => {
						// getSubscribtions();
						_refresh();
					})
					.catch(err => {
						Alert.alert(APP_NAME, err);
					});
				}}
			/>) : null}
			<Dialog.Container visible={visible}>
				<Dialog.Title>{buttonIndex === 2 ? 'Переименовать компанию' : 'Переименовать дело'}</Dialog.Title>
				<Dialog.Input value={casename} onChangeText={text => setCaseName(text)} />
				<Dialog.Button label="Отмена" onPress={() => {
					setVisible(false);
				}} />
				<Dialog.Button label="Сохранить" onPress={() => {
					if (casename.length) {
						// console.warn(selectedItem);
						if (buttonIndex === 2) {
							renameCompany({id: selectedItem.id, name: casename})
							.then(() => {
								// getSubscribtions();
								_refresh();
								setVisible(false);
							})
							.catch(err => {
								setVisible(false);
								Alert.alert(APP_NAME, err);
							});
						} else {
							renameCase({id: selectedItem.id, name: casename})
							.then(() => {
								// getSubscribtions();
								_refresh();
								setVisible(false);
							})
							.catch(err => {
								setVisible(false);
								Alert.alert(APP_NAME, err);
							});
						}
					} else {
						Alert.alert(APP_NAME, 'Укажите название!');
					}
				}} />
			</Dialog.Container>
		</View>
	);
};

const mstp = (state: RootState) => ({
	allSubscriptions: state.all.allSubscriptions,
	casesList: state.all.casesList,
	companiesList: state.all.companiesList,
	keywordsList: state.all.keywordsList,
	buttonIndex: state.buttons.buttonIndex,
	showItemMenu: state.buttons.showItemMenu,
	menuMode: state.buttons.menuMode,
	userProfile: state.user.userProfile,
	showScanner: state.buttons.showScanner,
});

const mdtp = (dispatch: Dispatch) => ({
    getSubscribtions: () => dispatch.all.getSubscribtions(),
	renameCase: payload => dispatch.all.renameCase(payload),
	renameCompany: payload => dispatch.all.renameCompany(payload),
	newSubscription: payload => dispatch.all.newSubscription(payload),
	setShowItemMenu: payload => dispatch.buttons.setShowItemMenu(payload),
	setButtonIndex: payload => dispatch.buttons.setButtonIndex(payload),
	setPushId: payload => dispatch.all.setPushId(payload),
	getMessages: () => dispatch.all.getMessages(),
});

export default connect(mstp, mdtp)(MainScreen);
