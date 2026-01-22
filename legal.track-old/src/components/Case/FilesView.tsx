import React, { useEffect, useRef } from 'react';
import {StyleSheet, Image, Alert, View, Text, TouchableOpacity, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import RecordView from './RecordView';
import NoteView from './NoteView';
import Dialog from "react-native-dialog";
import { APP_NAME } from '../../constants';

const FilesView = ({style, onRefresh, data, setNoteId, renameAudio, setNoteText, setShowRecord, setShowNote}) => {

	const [openView, setOpenView] = React.useState(false);
	const [tags, setTags] = React.useState(null);
	const [visible, setVisible] = React.useState(false);
	const [casename, setCaseName] = React.useState('');
	const [caseObj, setCaseObj] = React.useState(null);
	const [rawData, setRawData] = React.useState(null);

	const opacity = useRef(new Animated.Value(0));
	const height = useRef(new Animated.Value(0));

	useEffect(() => {
		setRawData(data);
	}, [data]);

	useEffect(() => {
		if (rawData) {
			let array = [];

			for (let i = 0; i < rawData.audios.length; i++) {
				array.push(<RecordView
					data={rawData.audios[i]}
					onShowMenu={() => {
						console.warn(rawData.audios[i]);
						setCaseName(rawData.audios[i].name);
						setCaseObj(rawData.audios[i]);
						setVisible(true);
					}}
				/>);
			}

			if (rawData.notes) {
				for (let i = 0; i < rawData.notes.length; i++) {
					array.push(<NoteView data={rawData.notes[i]} onClick={() => {
						setNoteId(rawData.notes[i].id);
						setNoteText(rawData.notes[i].text);
						setShowNote(true);
					}}/>);
				}
			}

			setTags(<Animated.View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				marginBottom: Common.getLengthByIPhone7(10),
				opacity: opacity.current,
				maxHeight: height.current.interpolate({ 
					inputRange: [0, 1], 
					outputRange: [0, 10000]
				})
			}}>
				{array}
			</Animated.View>);
		}
	}, [rawData]);

    return (
		<View style={[{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			minHeight: Common.getLengthByIPhone7(44),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
			overflow: 'hidden',
		}, style]}>
			<TouchableOpacity style={{
				height: Common.getLengthByIPhone7(44),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				zIndex: 200,
			}}
			onPress={() => {
				if (openView) {
					Animated.timing(height.current, {
						toValue: 0,
						duration: 300,
						easing: Easing.linear,
						useNativeDriver: false  // <-- neccessary
					}).start(() => {
						Animated.timing(opacity.current, {
						  toValue: 0,
						  duration: 300,
						  easing: Easing.linear,
						  useNativeDriver: false  // <-- neccessary
						}).start();
					});
				} else {
					Animated.timing(height.current, {
						toValue: 1,
						duration: 300,
						easing: Easing.linear,
						useNativeDriver: false  // <-- neccessary
					}).start(() => {
						Animated.timing(opacity.current, {
						  toValue: 1,
						  duration: 300,
						  easing: Easing.linear,
						  useNativeDriver: false  // <-- neccessary
						}).start();
					});
				}
				setOpenView(!openView);
			}}>
				<View style={{
					flexDirection: 'row',
					alignItems: 'center',
				}}>
					<Image
						source={require('./../../assets/ic-file.png')}
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
						Файлы
					</Text>
				</View>
				<Text style={{
					color: colors.ORANGE_COLOR,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(22),
				}}
				allowFontScaling={false}>
					{openView ? 'Скрыть' : 'Показать'}
				</Text>
			</TouchableOpacity>
			<Animated.View style={{
				marginTop: Common.getLengthByIPhone7(20),
				marginBottom: Common.getLengthByIPhone7(10),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				opacity: opacity.current,
				maxHeight: height.current.interpolate({ 
					inputRange: [0, 1], 
					outputRange: [0, 42]
				})
			}}>
				<TouchableOpacity style={{
					width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(52))/2,
					height: Common.getLengthByIPhone7(42),
					borderRadius: Common.getLengthByIPhone7(10),
					alignItems: 'center',
					justifyContent: 'center',
					backgroundColor: colors.ORANGE_COLOR,
				}}
				onPress={() => {
					setShowRecord(true);
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
						Добавить аудио
					</Text>
				</TouchableOpacity>
				<TouchableOpacity style={{
					width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(52))/2,
					height: Common.getLengthByIPhone7(42),
					borderRadius: Common.getLengthByIPhone7(10),
					alignItems: 'center',
					justifyContent: 'center',
					backgroundColor: colors.MAIN_COLOR,
				}}
				onPress={() => {
					setNoteId(0);
					setNoteText('');
					setShowNote(true);
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
						Добавить заметку
					</Text>
				</TouchableOpacity>
			</Animated.View>
			{tags}
			<Dialog.Container visible={visible}>
				<Dialog.Title>Переименовать аудиозапись</Dialog.Title>
				<Dialog.Input value={casename} onChangeText={text => setCaseName(text)} />
				<Dialog.Button label="Отмена" onPress={() => {
					setVisible(false);
				}} />
				<Dialog.Button label="Сохранить" onPress={() => {
					if (casename.length) {
						renameAudio({id: caseObj.id, name: casename})
						.then(resp => {
							setVisible(false);
							let dd = JSON.parse(JSON.stringify(rawData));
							// console.warn('iiii: ', dd);
							for (let i = 0; i < dd.audios.length; i++) {
								if (dd.audios[i].id == resp.id) {
									dd.audios[i] = resp;
									break;
								}
							}
							// dd.audios = resp;
							setRawData(dd);
							// if (onRefresh) {
							// 	onRefresh();
							// }
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
	// currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    setShowRecord: payload => dispatch.buttons.setShowRecord(payload),
	setShowNote: payload => dispatch.buttons.setShowNote(payload),
	setNoteId: payload => dispatch.buttons.setNoteId(payload),
	setNoteText: payload => dispatch.buttons.setNoteText(payload),
	renameAudio: payload => dispatch.all.renameAudio(payload),
});

export default connect(mstp, mdtp)(FilesView);