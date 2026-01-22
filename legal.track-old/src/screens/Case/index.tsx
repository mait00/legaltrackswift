import React, { useCallback, useEffect, useRef } from 'react';
import { Linking, Image, View, TouchableOpacity, ScrollView, Text, Share, Alert } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import { colors } from '../../styles';
import SidesView from '../../components/Case/SidesView';
import FilesView from '../../components/Case/FilesView';
import EventsView from '../../components/Case/EventsView';
import RecordModalView from '../../components/Case/RecordModalView';
import NoteModalView from '../../components/Case/NoteModalView';
import { APP_NAME } from '../../constants';
import Dialog from "react-native-dialog";

const CaseScreen = ({route, getCurrCase, newSubscription, setCurrCase, setShowNote, noteId, setNoteId, addNote, updateNote, uploadAudio, getCase, renameCase, getSubscribtions, setShowRecord}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);
	const [visible, setVisible] = React.useState(false);
	const [casename, setCaseName] = React.useState('');
	const [caseObj, setCaseObj] = React.useState(null);

	useEffect(() => {
		setBody(null);
		setCurrCase(getCurrentCase);
		getCurrentCase();
	}, []);

	const getCurrentCase = () => {
		console.warn('getCurrentCase');
		getCase(route.params.data.id)
		.then(data => {
			renderBody(data);
		})
		.catch(err => {

		});
	}

	const renderBody = data => {
		setCaseObj(data);
		setCaseName(data.name ? data.name : data.value);
		console.warn('route: ', data.instances);
		let Plaintiffs = [];
		let Defendants = [];
		let Third = [];

		for (let i = 0; i < data.sides.Plaintiffs.length; i++) {
			Plaintiffs.push(data.sides.Plaintiffs[i].Name);
		}

		for (let i = 0; i < data.sides.Defendants.length; i++) {
			Defendants.push(data.sides.Defendants[i].Name);
		}

		for (let i = 0; i < data.sides.Third.length; i++) {
			Third.push(data.sides.Third[i].Name);
		}

		let sides = [];

		if (Plaintiffs.length) {
			sides.push(<SidesView
				key={1}
				title={'Истцы'}
				icon={require('./../../assets/ic-sword.png')}
				style={{
					marginTop: Common.getLengthByIPhone7(20),
				}}
				data={Plaintiffs}
			/>);
		}
		if (Defendants.length) {
			sides.push(<SidesView
				key={2}
				title={'Ответчики'}
				icon={require('./../../assets/ic-shield.png')}
				style={{
					// marginTop: Common.getLengthByIPhone7(20),
				}}
				data={Defendants}
			/>);
		}
		if (Third.length) {
			sides.push(<SidesView
				key={3}
				title={'Третьи стороны'}
				icon={require('./../../assets/ic-persons.png')}
				style={{
					// marginTop: Common.getLengthByIPhone7(20),
				}}
				data={Third}
			/>);
		}

		console.warn('data.nearest_session: ', data.nearest_session);
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
					flexDirection: 'row',
					alignItems: 'center',
					justifyContent: 'space-between',
					marginTop: Common.getLengthByIPhone7(5),
					marginBottom: Common.getLengthByIPhone7(5),
				}}>
					<Text style={{
						maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(120),
						color: 'white',
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(20),
					}}
					allowFontScaling={false}>
						{data.name ? data.name : data.value}
					</Text>
					<TouchableOpacity style={{

					}}
					onPress={() => {
						setVisible(true);
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
				</View>
				{renderRow('Номер дела', data['case-number'])}
				{data.nearest_session || (data.court_name && data.court_name.length) ? renderRow('Суд', data.nearest_session ? data.nearest_session.court_name : data.court_name) : null}
				{data.nearest_session || (data.judge && data.judge.length) ? renderRow('Судья', data.nearest_session ? data.nearest_session.judge : data.judge) : null}
				{data.nearest_session ? renderRow('Ближайшее заседание', data.nearest_session ? Common.getRusDate(new Date(data.nearest_session.date)) : '') : null}
			</View>
			<View style={{
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'center',
				marginTop: Common.getLengthByIPhone7(30),
			}}>
				{data.subscribed ? null : (renderButton('Добавить', require('./../../assets/ic-case-add.png'), {marginRight: Common.getLengthByIPhone7(17)}, () => {
					newSubscription({
						type: 'case',
						value: data['case-number'],
						sou: false,
					})
					.then(() => {
						getSubscribtions();
						getCase(route.params.data.id)
						.then(data => {
							renderBody(data);
						})
						.catch(err => {

						});
					})
					.catch(err => {
						Alert.alert(APP_NAME, err);
						setVisible(false);
					});
				}))}
				{route.params.data.from === 'company' ? null : renderButton('Уведомления', require('./../../assets/ic-case-notify.png'), {marginRight: Common.getLengthByIPhone7(17)}, () => {
					console.warn(route.name);
					if (route.name === 'Case') {
						navigation.navigate('CaseNotify2', {data: data, muted_all: route.params.data.muted_all, muted_side: route.params.data.muted_side, action: () => {
							getCurrentCase();
						}});
					} else if (route.name === 'CaseNotify') {
						navigation.navigate('CaseNotify3', {data: data, muted_all: route.params.data.muted_all, muted_side: route.params.data.muted_side, action: () => {
							getCurrentCase();
						}});
					} else if (route.name === 'Case3') {
						navigation.navigate('CaseNotify4', {data: data, muted_all: route.params.data.muted_all, muted_side: route.params.data.muted_side, action: () => {
							getCurrentCase();
						}});
					}
				})}
				{renderButton('См. источник', require('./../../assets/ic-case-link.png'), {marginRight: Common.getLengthByIPhone7(17)}, () => {
					console.warn(data['card-link']);
					Linking.openURL(data['card-link']);
				})}
				{renderButton('Поделиться', require('./../../assets/ic-case-share.png'), {}, () => {
					if (data['card-link']) {
						Share.share({
							message: data['card-link'],
						})
						.then(() => {
							
						});
					} else {
						Alert.alert(APP_NAME, 'Формат ссылки неверен!');
					}
				})}
			</View>
			{sides}
			{route.params.data.from === 'company' ? null : (<EventsView
				key={1}
				title={'События'}
				icon={require('./../../assets/ic-events.png')}
				style={{
					// marginTop: Common.getLengthByIPhone7(20),
				}}
				data={data.instances}
			/>)}
			{route.params.data.from === 'company' ? null : (<FilesView
				style={{
					// marginTop: Common.getLengthByIPhone7(10),
				}}
				data={data}
				onRefresh={() => {
					getCase(route.params.data.id)
					.then(data => {
						renderBody(data);
					})
					.catch(err => {

					});
				}}
			/>)}
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
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'space-between',
			paddingTop: Common.getLengthByIPhone7(4),
			paddingBottom: Common.getLengthByIPhone7(4),
		}}>
			<Text style={{
				width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72)) / 2,
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
			<Text style={{
				width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72)) / 2,
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
				<Dialog.Title>Переименовать дело</Dialog.Title>
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
							getCase(route.params.data.id)
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
			<RecordModalView
				id={caseObj ? caseObj.id : null}
				onSave={uri => {
					console.warn('onSave: ', uri);
					setShowRecord(false);
					// setTimeout(() => {
						uploadAudio({id: caseObj.id, file: uri})
						.then(() => {
							getCase(route.params.data.id)
							.then(data => {
								renderBody(data);
							})
							.catch(err => {

							});
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					// }, 500);
				}}
			/>
			<NoteModalView
				onSave={text => {
					setShowNote(false);
					let id = noteId;
					console.warn('id: ', id);
					if (noteId == 0) {
						id = caseObj.id;
						addNote({id: id, text: text})
						.then(() => {
							getCase(route.params.data.id)
							.then(data => {
								renderBody(data);
							})
							.catch(err => {

							});
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					} else {
						updateNote({id: id, text: text})
						.then(() => {
							getCase(route.params.data.id)
							.then(data => {
								renderBody(data);
							})
							.catch(err => {

							});
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					}
				}}
			/>
		</View>
	);
};

const mstp = (state: RootState) => ({
	currentCase: state.all.currentCase,
	getCurrCase: state.all.getCurrCase,
	noteId: state.buttons.noteId,
});

const mdtp = (dispatch: Dispatch) => ({
	setCurrCase: () => dispatch.all.setCurrCase,
    getCase: payload => dispatch.all.getCase(payload),
	renameCase: payload => dispatch.all.renameCase(payload),
	newSubscription: payload => dispatch.all.newSubscription(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
	uploadAudio: payload => dispatch.all.uploadAudio(payload),
	addNote: payload => dispatch.all.addNote(payload),
	updateNote: payload => dispatch.all.updateNote(payload),
	setShowRecord: payload => dispatch.buttons.setShowRecord(payload),
	setNoteId: payload => dispatch.buttons.setNoteId(payload),
	setShowNote: payload => dispatch.buttons.setShowNote(payload),
});

export default connect(mstp, mdtp)(CaseScreen);
