import React, { useEffect, useRef } from 'react';
import {Platform, Image, View, Text, TouchableOpacity, ActivityIndicator, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import AudioRecorderPlayer from 'react-native-audio-recorder-player';
import RNFetchBlob from 'rn-fetch-blob';

const audioRecorderPlayer = new AudioRecorderPlayer();

const RecordView = ({data, onShowMenu}) => {

	const [openView, setOpenView] = React.useState(false);
	const [play, setPlay] = React.useState(false);
	const [button, setButton] = React.useState(<Image source={require('./../../assets/ic-play.png')} 
		style={{
			width: Common.getLengthByIPhone7(30),
			height: Common.getLengthByIPhone7(30),
			resizeMode: 'contain',
		}}
	/>);

	useEffect(() => {
		if (play) {

			setButton(<ActivityIndicator style={{
				marginLeft: 3,
				marginRight: 8,
			}} />);
			const dir = RNFetchBlob.fs.dirs.DocumentDir;
			const path = `${dir}/testt.mp4`;

			RNFetchBlob.config({
				fileCache: false,
				// appendExt: fileExtension,
				path,
			}).fetch('GET', data.url)
			.then(res => {
				setButton(<View style={{
					marginRight: 6,
					marginLeft: 6,
					width: Common.getLengthByIPhone7(20),
					height: Common.getLengthByIPhone7(20),
					borderRadius: Common.getLengthByIPhone7(6),
					backgroundColor: colors.ORANGE_COLOR,
				}} />);
				// console.warn('res: ', res);
				const internalUrl = 'file://' + res.path();//`${Platform.OS === 'android' ? 'file://' : ''}${res.path()}`;
				console.warn('internalUrl: ', internalUrl);
				// audioRecorderPlayer.startPlayer(internalUrl);
				audioRecorderPlayer.startPlayer(internalUrl)
				.then(msg => {
					console.warn(msg);
					audioRecorderPlayer.addPlayBackListener((e) => {
						// console.warn(audioRecorderPlayer.mmssss(Math.floor(e.currentPosition)));
						// console.warn('duration: ', Math.floor(e.duration), ' position: ', Math.floor(e.currentPosition));
						if (Math.floor(e.duration) <= Math.floor(e.currentPosition)) {
							audioRecorderPlayer.stopPlayer();
							audioRecorderPlayer.removePlayBackListener();
							setPlay(false);
							setButton(<Image source={require('./../../assets/ic-play.png')} 
								style={{
									width: Common.getLengthByIPhone7(30),
									height: Common.getLengthByIPhone7(30),
									resizeMode: 'contain',
								}}
							/>);
						}
						// this.setState({
						// 	currentPositionSec: e.currentPosition,
						// 	currentDurationSec: e.duration,
						// 	playTime: this.audioRecorderPlayer.mmssss(Math.floor(e.currentPosition)),
						// 	duration: this.audioRecorderPlayer.mmssss(Math.floor(e.duration)),
						// });
						// return;
					});
				})
				.catch(err => {

				});
			});
		} else {
			audioRecorderPlayer.stopPlayer();
			audioRecorderPlayer.removePlayBackListener();
			setPlay(false);
			setButton(<Image source={require('./../../assets/ic-play.png')} 
				style={{
					width: Common.getLengthByIPhone7(30),
					height: Common.getLengthByIPhone7(30),
					resizeMode: 'contain',
				}}
			/>);
		}
	}, [play]);

	return (<TouchableOpacity style={{
		width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
		minHeight: Common.getLengthByIPhone7(44),
		marginBottom: Common.getLengthByIPhone7(8),
		borderRadius: Common.getLengthByIPhone7(12),
		paddingLeft: Common.getLengthByIPhone7(8),
		paddingRight: Common.getLengthByIPhone7(8),
		paddingTop: Common.getLengthByIPhone7(8),
		paddingBottom: Common.getLengthByIPhone7(8),
		backgroundColor: 'white',
		flexDirection: 'row',
		alignItems: 'center',
		justifyContent: 'space-between',
		shadowColor: "#000",
		shadowOffset: {
			width: 0,
			height: 2,
		},
		shadowOpacity: 0.08,
		shadowRadius: 7.00,
		elevation: 1,
	}}
	onPress={() => {
		setPlay(!play);
	}}>
		<View style={{
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}}>
			{button}
			<View style={{
				width: Common.getLengthByIPhone7(220),
				alignItems: 'flex-start',
			}}>
				<Text style={{
					// backgroundColor: 'red',
					width: Common.getLengthByIPhone7(220),
					marginLeft: 3,
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(17),
				}}
				allowFontScaling={false}>
					{data.name && data.name.length ? data.name : data.url}
				</Text>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(10),
					lineHeight: Common.getLengthByIPhone7(12),
					opacity: 0.5,
					marginTop: Common.getLengthByIPhone7(5),
				}}
				allowFontScaling={false}>
					{Common.getRusDate(new Date(data.created_at))}
				</Text>
			</View>
		</View>
		<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(32),
			height: Common.getLengthByIPhone7(40),
			alignItems: 'center',
			justifyContent: 'center',
		}}
		onPress={() => {
			onShowMenu();
		}}>
			<Image source={require('./../../assets/ic-button-rename.png')}
				style={{
					width: Common.getLengthByIPhone7(36),
					height: Common.getLengthByIPhone7(36),
					tintColor: colors.ORANGE_COLOR,
					resizeMode: 'contain',
				}}
			/>
		</TouchableOpacity>
	</TouchableOpacity>);
};

const mstp = (state: RootState) => ({
	// currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    setShowRecord: payload => dispatch.buttons.setShowRecord(payload),
});

export default connect(mstp, mdtp)(RecordView);