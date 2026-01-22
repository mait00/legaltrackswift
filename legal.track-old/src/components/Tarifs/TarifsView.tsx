import React, { useCallback, useEffect, useRef } from 'react';
import { Platform, ScrollView, View, TouchableOpacity, Linking, Image, Text, Alert } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import RNIap, {
	purchaseErrorListener,
	purchaseUpdatedListener,
	acknowledgePurchaseAndroid,
	consumePurchaseAndroid,
	type ProductPurchase,
	type PurchaseError
} from 'react-native-iap';
import {APP_NAME} from './../../constants';

// import * as RNIap from 'react-native-iap';

const itemSkus = Platform.select({
	ios: {
	  '1': 'lt.prof1',
	  '6': 'lt.prof6',
	  '12': 'lt.prof12',
	},
	android: {
		'1': 'lt.prof1',
		'6': 'lt.prof6',
		'12': 'lt.prof12',
	}
});

const itemSkus2 = Platform.select({
	ios: [
	  'lt.prof1',
	  'lt.prof6',
	  'lt.prof12',
	],
	android: [
		'lt.prof1',
		'lt.prof6',
		'lt.prof12',
	]
});

const TarifsView = ({setRequestGoingStatus, userProfile, tarifs, getTarifs, cancelTarif, validateReceipt, getProfile}) => {

	const navigation = useNavigation();

	const [tarifView, setTarifView] = React.useState([]);
	const [header, setHeader] = React.useState(null);

	useEffect(() => {
		renderView();
	}, []);

	useEffect(() => {
		renderView();
	}, [tarifs]);

	const renderView = () => {
		console.warn(tarifs);
		if (tarifs?.active) {
			setHeader(<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				height: Common.getLengthByIPhone7(114),
				borderRadius: Common.getLengthByIPhone7(11),
				backgroundColor: 'rgba(235, 94, 31, 0.05)',
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'flex-start',
				marginBottom: Common.getLengthByIPhone7(8),
			}}>
				<Image source={require('./../../assets/ic-tarif-prof.png')}
					style={{
						width: Common.getLengthByIPhone7(89),
						height: Common.getLengthByIPhone7(89),
						resizeMode: 'contain',
					}}
				/>
				<View style={{
					marginLeft: Common.getLengthByIPhone7(20),
					alignItems: 'center',
				}}>
					<Text style={{
						width: Common.getLengthByIPhone7(200),
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'center',
						fontSize: Common.getLengthByIPhone7(15),
						lineHeight: Common.getLengthByIPhone7(19),
					}}
					allowFontScaling={false}>
						{tarifs?.header}
					</Text>
					<TouchableOpacity style={{
						marginTop: Common.getLengthByIPhone7(13),
						flexDirection: 'row',
						alignItems: 'center',
					}}
					onPress={() => {
						cancelTarif()
						.then(() => {
							getTarifs()
							.then(() => {

							})
							.catch(err => {
								
							});
						})
						.catch(err => {

						});
					}}>
						<Text style={{
							color: colors.BLACK,
							fontFamily: 'SFProDisplay-Regular',
							fontWeight: 'normal',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(12),
						}}
						allowFontScaling={false}>
							Отменить
						</Text>
					</TouchableOpacity>
				</View>
			</View>);
		} else {
			if (tarifs?.header?.length) {
				setHeader(<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					height: Common.getLengthByIPhone7(114),
					borderRadius: Common.getLengthByIPhone7(11),
					backgroundColor: 'rgba(235, 94, 31, 0.05)',
					alignItems: 'center',
					justifyContent: 'center',
					marginBottom: Common.getLengthByIPhone7(8),
				}}>
					<Text style={{
						width: Common.getLengthByIPhone7(300),
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'center',
						fontSize: Common.getLengthByIPhone7(13),
					}}
					allowFontScaling={false}>
						{tarifs?.header}
					</Text>
					<Text style={{
						marginTop: 4,
						width: Common.getLengthByIPhone7(300),
						color: colors.BLACK,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'normal',
						textAlign: 'center',
						fontSize: Common.getLengthByIPhone7(12),
					}}
					allowFontScaling={false}>
						{tarifs?.text}
					</Text>
				</View>);
			} else {
				setHeader(null);
			}
		}

		if (userProfile?.phone === '77777777777') {
			let array = [];
			for (let i = 0; i < tarifs?.tarifs.length; i++) {
				array.push(renderTarif('rgba(235, 94, 31, 0.05)', require('./../../assets/ic-tarif-prof.png'), tarifs?.tarifs[i].name, tarifs?.tarifs[i].price + ' р.', '', () => {
					setRequestGoingStatus(true);
					RNIap.requestPurchase(itemSkus[tarifs?.tarifs[i].month.toString()], false)
					.then(() => {
					  console.warn('RNIap.requestPurchase');
					})
					.catch(err => {
					  console.warn('err requestPurchase: '+err);
					  setRequestGoingStatus(false);
					});
				}));
			}
			setTarifView(array);
			RNIap.initConnection()
			.then(() => {
				console.warn('initConnection');

				RNIap.getProducts(itemSkus2).then(products => {
					//handle success of fetch product list
					console.warn('products: '+JSON.stringify(products));
					if (Platform.OS === 'android') {
						RNIap.flushFailedPurchasesCachedAsPendingAndroid()
						.then(() => {

						})
						.catch(err => {
						
						});
					} else {
						RNIap.clearTransactionIOS()
						.then(() => {

						})
						.catch(err => {

						});
					}
				}).catch((error) => {
					console.warn('itemSkus2: ', itemSkus2);
					console.warn(error);
				});
			})
			.catch(err => {
				console.warn('initConnection err: '+err);
			});

			this.purchaseUpdateSubscription = purchaseUpdatedListener((purchase: InAppPurchase | SubscriptionPurchase | ProductPurchase ) => {
				console.warn('purchaseUpdatedListener', purchase);

				const receipt = purchase.transactionReceipt;
				console.warn('receipt '+receipt);
				if (receipt) {
					RNIap.finishTransaction(purchase, true)
					.then(result => {
					console.warn('finishTransaction success: '+JSON.stringify(result));
					})
					.catch(err => {
						console.warn('finishTransaction err: '+JSON.stringify(err));
					});

					validateReceipt({receipt: receipt, store_type: Platform.OS === 'ios' ? 'appstore' : 'googleplay', tarif: purchase.productId})
					.then(id => {
						getProfile()
						.then(() => {
							setRequestGoingStatus(false);
							navigation.goBack(null);
						})
						.catch(err => {
							setRequestGoingStatus(false);
							navigation.goBack(null);
						});
						// if (this.props.onSuccess) {
						// 	this.props.onSuccess(id);
						// }
					})
					.catch(err => {
						setRequestGoingStatus(false);
						Alert.alert(APP_NAME, err);
					});
				}
			});
		} else {
			let array = [];
			for (let i = 0; i < tarifs?.tarifs.length; i++) {
				array.push(renderTarif('rgba(235, 94, 31, 0.05)', require('./../../assets/ic-tarif-prof.png'), tarifs?.tarifs[i].name, tarifs?.tarifs[i].price + ' р.', '', () => {
					if (tarifs?.tarifs[i].url?.length) {
						Linking.openURL(tarifs?.tarifs[i].url);
					}
				}));
			}
			setTarifView(array);
		}
	}

	const renderTarif = (backgroundColor, icon, name, subtitle, subtitle2, action) => {
		return (<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			height: Common.getLengthByIPhone7(114),
			borderRadius: Common.getLengthByIPhone7(11),
			backgroundColor: backgroundColor,
			marginBottom: Common.getLengthByIPhone7(8),
			paddingLeft: Common.getLengthByIPhone7(14),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}}
		onPress={() => {
			action();
		}}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(89),
					height: Common.getLengthByIPhone7(89),
					resizeMode: 'contain',
				}}
			/>
			<View style={{
				marginLeft: Common.getLengthByIPhone7(20),
			}}>
				<Text style={{
					// marginTop: Common.getLengthByIPhone7(18),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(16),
					lineHeight: Common.getLengthByIPhone7(19),
				}}
				allowFontScaling={false}>
					{name}
				</Text>
				<View style={{
					marginTop: Common.getLengthByIPhone7(13),
					flexDirection: 'row',
					alignItems: 'center',
				}}>
					<Text style={{
						color: colors.ORANGE_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(18),
						lineHeight: Common.getLengthByIPhone7(21),
					}}
					allowFontScaling={false}>
						{subtitle}
					</Text>
					<Text style={{
						marginLeft: Common.getLengthByIPhone7(7),
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(12),
						lineHeight: Common.getLengthByIPhone7(14),
						textDecorationLine: 'line-through',
					}}
					allowFontScaling={false}>
						{subtitle2}
					</Text>
				</View>
			</View>
		</TouchableOpacity>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<ScrollView style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				backgroundColor: 'white',
			}}
			contentContainerStyle={{
				alignItems: 'center',
				justifyContent: 'flex-start',
			}}>
				{header}
				{tarifView}
			</ScrollView>
		</View>
	);
};

const mstp = (state: RootState) => ({
	tarifs: state.user.tarifs,
	userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
	setRequestGoingStatus: payload => dispatch.user.setRequestGoingStatus(payload),
	validateReceipt: payload => dispatch.all.validateReceipt(payload),
	getProfile: () => dispatch.user.getProfile(),
	getTarifs: () => dispatch.user.getTarifs(),
	cancelTarif: () => dispatch.user.cancelTarif(),
});

export default connect(mstp, mdtp)(TarifsView);
