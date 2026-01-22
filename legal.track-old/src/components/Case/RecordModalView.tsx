import React, { useEffect } from 'react';
import {Image, Platform, Alert, View, Text, TouchableOpacity, Share} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../../utilities/Common';
import { colors } from './../../styles';
import Modal from "react-native-modal";
import { APP_NAME } from './../../constants';
import AudioRecorderPlayer from 'react-native-audio-recorder-player';
import RNFetchBlob from 'rn-fetch-blob';

const audioRecorderPlayer = new AudioRecorderPlayer();

const RecordModalView = ({id, showRecord, onSave, setShowRecord}) => {

	const navigation = useNavigation();

	const [mode, setMode] = React.useState(0);
	const [uri, setUri] = React.useState(null);
	const [time, setTime] = React.useState('00:00:00');

	useEffect(() => {
		if (mode === 1) {
			const dirs = RNFetchBlob.fs.dirs;
			const path = Platform.select({
				ios: 'hello.mp4',
				android: `${dirs.CacheDir}/hello.mp3`,
			});
			audioRecorderPlayer.startRecorder(path)
			.then(result => {
				console.warn('uri: ', result);
				setUri(result);
				audioRecorderPlayer.addRecordBackListener((e) => {
					setTime(audioRecorderPlayer.mmssss(Math.floor(e.currentPosition)));
					// console.warn(audioRecorderPlayer.mmssss(Math.floor(e.currentPosition)));
					// this.setState({
					// 	recordSecs: e.currentPosition,
					// 	recordTime: audioRecorderPlayer.mmssss(
					// 		Math.floor(e.currentPosition),
					// 	),
					// });
				});
			})
			.catch(err => {

			});
		} else {
			audioRecorderPlayer.stopRecorder()
			.then(result => {
				audioRecorderPlayer.removeRecordBackListener();
				// uploadAudio({id: id, file: uri});
				if (onSave) {
					onSave(uri);
					setTime('00:00:00');
				}
			})
			.catch(err => {

			});
		}
	}, [mode]);

    return (
		<Modal
			isVisible={showRecord}
			backdropColor={colors.MAIN_COLOR}
			animationIn={'fadeIn'}
			animationOut={'fadeOut'}
			backdropOpacity={0.54}
			style={{
				flex: 1,
				alignItems: 'center',
				justifyContent: 'center',
			}}
		>
			<View style={{
				width: Common.getLengthByIPhone7(0),
				marginBottom: Common.getLengthByIPhone7(14),
				alignItems: 'flex-end',
				justifyContent: 'center',
				paddingLeft: Common.getLengthByIPhone7(20),
				paddingRight: Common.getLengthByIPhone7(20),
			}}>
				<TouchableOpacity style={{
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
					if (mode === 1) {
						Alert.alert(
							APP_NAME,
							"Вы хотите завершить запись?",
							[
							  {
								text: "Нет",
								onPress: () => console.log("Cancel Pressed"),
								style: "cancel"
							  },
							  { text: "Да", onPress: () => {
								setTime('00:00:00');
								// setShowRecord(false);
								setMode(0);
							  }}
							]
						  );
					  
					} else {
						setTime('00:00:00');
						setShowRecord(false);
					}
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
			<View style={{
				width: Common.getLengthByIPhone7(270),
				borderRadius: Common.getLengthByIPhone7(14),
				alignItems: 'center',
				justifyContent: 'flex-end',
				backgroundColor: 'white',
			}}>
				<View style={{
					width: Common.getLengthByIPhone7(270),
					paddingLeft: Common.getLengthByIPhone7(20),
					paddingRight: Common.getLengthByIPhone7(20),
					paddingTop: Common.getLengthByIPhone7(18),
					paddingBottom: Common.getLengthByIPhone7(18),
					borderBottomColor: '#C6C6C8',
					borderBottomWidth: 1,
					alignItems: 'center',
					justifyContent: 'center',
				}}>
					<Text style={{
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(20),
						lineHeight: Common.getLengthByIPhone7(24),
						letterSpacing: -0.022,
					}}
					allowFontScaling={false}>
						Аудиозапись
					</Text>
				</View>
				<Text style={{
					marginTop: Common.getLengthByIPhone7(20),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(20),
					lineHeight: Common.getLengthByIPhone7(24),
					letterSpacing: -0.022,
				}}
				allowFontScaling={false}>
					{time}
				</Text>
				<TouchableOpacity style={{
					width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(52))/2,
					height: Common.getLengthByIPhone7(42),
					borderRadius: Common.getLengthByIPhone7(10),
					alignItems: 'center',
					justifyContent: 'center',
					backgroundColor: colors.MAIN_COLOR,
					marginTop: Common.getLengthByIPhone7(20),
					marginBottom: Common.getLengthByIPhone7(20),
				}}
				onPress={() => {
					setMode(mode === 0 ? 1 : 0);
				}}>
					<Text style={{
						color: 'white',
						fontFamily: 'SFProText-Regular',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(14),
						lineHeight: Common.getLengthByIPhone7(22),
					}}
					allowFontScaling={false}>
						{mode === 0 ? 'Старт' : 'Стоп'}
					</Text>
				</TouchableOpacity>
			</View>
		</Modal>
	);
};

const mstp = (state: RootState) => ({
	showRecord: state.buttons.showRecord,
	// buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowRecord: payload => dispatch.buttons.setShowRecord(payload),
});

export default connect(mstp, mdtp)(RecordModalView);