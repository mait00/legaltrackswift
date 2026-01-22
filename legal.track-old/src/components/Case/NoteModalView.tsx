import React, { useEffect } from 'react';
import {Image, KeyboardAvoidingView, Platform, TextInput, Alert, View, Text, TouchableOpacity, Share} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../../utilities/Common';
import { colors } from './../../styles';
import Modal from "react-native-modal";
import { APP_NAME } from './../../constants';

const NoteModalView = ({showNote, setNoteText, noteText, onSave, setShowNote}) => {

	const navigation = useNavigation();

	const [mode, setMode] = React.useState(0);
	const [uri, setUri] = React.useState(null);
	const [text, setText] = React.useState('');

	useEffect(() => {
		setText(noteText);
	}, [noteText]);

    return (
		<Modal
			isVisible={showNote}
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
			<KeyboardAvoidingView
				behavior={Platform.OS === "ios" ? "padding" : "height"}
				style={{
					width: Common.getLengthByIPhone7(0),
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
					setNoteText('');
					setShowNote(false);
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
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(14),
				alignItems: 'center',
				justifyContent: 'flex-end',
				backgroundColor: 'white',
			}}>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(80),
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
						Заметка
					</Text>
				</View>
				<TextInput
					style={{
						marginTop: Common.getLengthByIPhone7(20),
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(80),
						height: Common.getLengthByIPhone7(200),
						borderRadius: Common.getLengthByIPhone7(12),
						paddingLeft: Common.getLengthByIPhone7(15),
						paddingRight: Common.getLengthByIPhone7(15),
						borderColor: '#C6C6C8',
						borderWidth: 1,
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProText-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(14),
						lineHeight: Common.getLengthByIPhone7(22),
					}}
					multiline={true}
					numberOfLines={4}
					onChangeText={(text) => setText(text)}
					value={text}
				/>
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
					if (text.length) {
						if (onSave) {
							onSave(text);
						}
					} else {
						Alert.alert(APP_NAME, 'Введите текст заметки!');
					}
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
						Сохранить
					</Text>
				</TouchableOpacity>
			</View>
			</KeyboardAvoidingView>
		</Modal>
	);
};

const mstp = (state: RootState) => ({
	showNote: state.buttons.showNote,
	noteText: state.buttons.noteText,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowNote: payload => dispatch.buttons.setShowNote(payload),
	setNoteText: payload => dispatch.buttons.setNoteText(payload),
});

export default connect(mstp, mdtp)(NoteModalView);