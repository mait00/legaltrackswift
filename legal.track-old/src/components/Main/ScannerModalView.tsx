import React, { useEffect, useRef } from 'react';
import {Image, Alert, Text, Dimensions, View, Platform, TouchableOpacity, Linking} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../../utilities/Common';
import { colors } from './../../styles';
import Modal from "react-native-modal";
import { APP_NAME } from './../../constants';
import { RNCamera } from 'react-native-camera';
import MaskView from './../../components/Scanner/MaskView'; 
import {check, request, PERMISSIONS, RESULTS} from 'react-native-permissions';

const ScannerModalView = ({setShowScanner, onScan, showScanner, setBarcodeList, barcodeList}) => {

	const navigation = useNavigation();

	const camera = useRef(null);
	const [ratio, setRatio] = React.useState(1);
	const [type, setType] = React.useState('back');
	const [flashMode, setFlashMode] = React.useState(RNCamera.Constants.FlashMode.off);
	const [granted, setGranted] = React.useState(true);
	const [body, setBody] = React.useState(null);

	useEffect(() => {
		if (granted) {
			setBody(renderCamera());
		} else {
			setBody(renderDenied());
		}
	}, [granted]);

	useEffect(() => {
		check(Platform.OS == 'ios' ? PERMISSIONS.IOS.CAMERA : PERMISSIONS.ANDROID.CAMERA)
		.then(result => {
			console.warn('result: ', result);
			switch (result) {
				case RESULTS.UNAVAILABLE:
					console.warn('This feature is not available (on this device / in this context)');
					// setGranted(true); 
					request(Platform.OS == 'ios' ? PERMISSIONS.IOS.CAMERA : PERMISSIONS.ANDROID.CAMERA)
					.then(result => {
						console.warn('result2222: '+result);
					});
					break;
				case RESULTS.DENIED:
					console.warn('The permission has not been requested / is denied but requestable');
					request(Platform.OS == 'ios' ? PERMISSIONS.IOS.CAMERA : PERMISSIONS.ANDROID.CAMERA)
					.then(result => {
						console.warn('result: '+result);
					});
					break;
				case RESULTS.LIMITED:
					console.warn('The permission is limited: some actions are possible');
					setGranted(true);
				break;
				case RESULTS.GRANTED:
					console.warn('The permission is granted');
					setGranted(true);
				break;
				case RESULTS.BLOCKED:
					setGranted(false);
					console.warn('The permission is denied and not requestable anymore');
					Alert.alert(
						APP_NAME,
						"Для работы приложения необходим доступ к камере телефона!",
						[
						{
							text: "Отмена",
							onPress: () => console.log("Cancel Pressed"),
							style: "cancel"
						},
						{ text: "Настройки", onPress: () => {
							Linking.openSettings();
						}}
						],
						{ cancelable: false }
					);
					break;
			}
		})
		.catch((error) => {
			setGranted(false);
		});
	}, []);

	const handleMountError = ({ message }) => {
		console.error(message);
	}
	
	const collectPictureSizes = async () => {
		if (camera.current) {
		  const pictureSizes = await camera.current.getAvailablePictureSizesAsync(ratio);
		  let pictureSizeId = 0;
		  if (Platform.OS === 'ios') {
			pictureSizeId = pictureSizes.indexOf('High');
		  } else {
			// returned array is sorted in ascending order - default size is the largest one
			pictureSizeId = pictureSizes.length-1;
		  }
		//   this.setState({ pictureSizes, pictureSizeId, pictureSize: pictureSizes[pictureSizeId] });
		}
	};

	const renderDenied = () => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			height: Dimensions.get('screen').height,
			alignItems: 'center',
			justifyContent: 'center',
			backgroundColor: 'white',
		}}>
			<Text style={{
				maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(60),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(20),
			}}
			allowFontScaling={false}>
				{`Для работы приложения необходим доступ к камере телефона! Перейдите в\n`}<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(20),
					textDecorationLine: 'underline'
				}}
				onPress={() => {
					Linking.openSettings();
				}}
				allowFontScaling={false}>
					Настройки
				</Text>{`\nи разрешите доступ`}
			</Text>
		</View>);
	}

	useEffect(() => {
		if (barcodeList) {
			let case_id = barcodeList.split('.ru/');
			if (case_id !== null && case_id.length === 2) {
				case_id = case_id[1].split('/');
				case_id = case_id[0];
				if (onScan) {
					onScan(case_id);
				}
				setShowScanner(false);
			}
		}
	}, [barcodeList]);

	const renderCamera = () => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			height: Dimensions.get('screen').height,
			alignItems: 'center',
			justifyContent: 'center',
			backgroundColor: 'white',
		}}>
			<RNCamera
				ref={ref => {
					// this.camera = ref;
				}}
				style={{
					width: Common.getLengthByIPhone7(0),
					position: 'absolute',
					left: 0,
					top: 0,
					bottom: 0,
				}}
				barCodeTypes={[
					RNCamera.Constants.BarCodeType.qr,
				]}
				onBarCodeRead={code => {
					// console.warn('code2: '+JSON.stringify(code));
					// return;
					let width = 0;
					let height = 0;

					if(Platform.OS == 'ios') {
						width = code.bounds.size.width;
						height = code.bounds.size.height;
						if(width < Common.getLengthByIPhone7(190) && height < Common.getLengthByIPhone7(190)) {
							if(
								(code.bounds.origin.x > Math.round((Dimensions.get('window').width - Common.getLengthByIPhone7(200))/2)) &&
							(code.bounds.origin.y > Math.round((Dimensions.get('window').height - Common.getLengthByIPhone7(100) - (Common.getLengthByIPhone7(194) - 4))/2))) {
							if (barcodeList != code.data) {
								setBarcodeList(code.data);
								console.warn('barcodeList: ', barcodeList, ' code: ', code.data);
								// console.warn('code: '+JSON.stringify(code));
								
							}
							}
						}
					} else {
						if (barcodeList != code.data) {
							setBarcodeList(code.data);
							console.warn('code: '+JSON.stringify(code));
							// let case_id = code.data.split('.ru/');
							// if (case_id !== null && case_id.length === 2) {
							// 	case_id = case_id[1].split('/');
							// 	case_id = case_id[0];
							// 	if (onScan) {
							// 		onScan(case_id);
							// 	}
							// 	setShowScanner(false);
							// }
						}
					}

				}}
				onCameraReady={collectPictureSizes}
				type={type}
				flashMode={flashMode}
				autoFocus='on'
				zoom={0}
				whiteBalance='auto'
				ratio='4:3'
				pictureSize={undefined}
				onMountError={handleMountError}
			/>
			<MaskView/>
		</View>);
	}

    return (
		<Modal
			isVisible={showScanner}
			backdropColor={colors.MAIN_COLOR}
			// animationIn={'fadeIn'}
			// animationOut={'fadeOut'}
			backdropOpacity={0.54}
			style={{
				flex: 1,
				alignItems: 'center',
				justifyContent: 'center',
			}}
		>
			<View style={{
				width: Common.getLengthByIPhone7(0),
				height: Dimensions.get('screen').height,
				alignItems: 'center',
				justifyContent: 'center',
				backgroundColor: 'white',
			}}>
				{body}
				<TouchableOpacity style={{
					position: 'absolute',
					top: Common.getLengthByIPhone7(60),
					right: Common.getLengthByIPhone7(20),
					width: Common.getLengthByIPhone7(46),
					height: Common.getLengthByIPhone7(46),
					borderRadius: Common.getLengthByIPhone7(23),
					alignItems: 'center',
					justifyContent: 'center',
					backgroundColor: 'white',
					shadowColor: 'black',
					shadowOffset: { width: 0, height: 2 },
					shadowOpacity: 0.15,
					shadowRadius: 7,
					elevation: 4,
				}}
				onPress={() => {
					setShowScanner(false);
				}}>
					<Image source={require('./../../assets/ic-menu-cancel.png')}
						style={{
							width: Common.getLengthByIPhone7(17),
							height: Common.getLengthByIPhone7(17),
							resizeMode: 'contain',
						}}
					/>
				</TouchableOpacity>
			</View>
		</Modal>
	);
};

const mstp = (state: RootState) => ({
	showScanner: state.buttons.showScanner,
	barcodeList: state.all.barcodeList,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowScanner: payload => dispatch.buttons.setShowScanner(payload),
	setBarcodeList: payload => dispatch.all.setBarcodeList(payload),
});

export default connect(mstp, mdtp)(ScannerModalView);