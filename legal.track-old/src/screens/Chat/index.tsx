import React, { useCallback, useEffect, useRef } from 'react';
import { Image, Platform, View, TouchableOpacity, Keyboard, KeyboardAvoidingView, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import PlaceholderView from '../../components/PlaceholderView';
import { GiftedChat, InputToolbar, Composer, Send, Bubble } from 'react-native-gifted-chat';
import ru from 'dayjs/locale/ru';

const ChatScreen = ({userProfile, setRequestGoingStatus, sendMessage, getMessages, messageList}) => {

	const navigation = useNavigation();
	const [messages, setMessages] = React.useState([]);

	let timer = null;
	// <PlaceholderView
	// 			icon={require('./../../assets/ic-placeholder-chat.png')}
	// 			title={'Готовы помочь!'}
	// 			subtitle={'Опишите вашу проблему и мы обязательно поможем вам!'}
	// 		/>

	useFocusEffect(
		React.useCallback(() => {
		  
			setRequestGoingStatus(true);
			getMessages();
			timer = setInterval(() => {
				getMessages();
			}, 5000);
			return () => {
				clearInterval(timer);
			};
		}, [])
	);

	useEffect(() => {
		setMessages([]);
		getMessages();
	}, []);

	useEffect(() => {
		let array = [];
		for (let i = 0; i < messageList.length; i++) {
			array.push({
			  _id: Math.random(),
			  text: messageList[i].text,
			  createdAt: new Date(messageList[i].datetime),
			  user: {
				_id: messageList[i].is_admin_answer ? 0 : userProfile.id,
				name: messageList[i].admin_name,
			  }
			});
		}
		console.warn('messageList: ', array[0]);
		array.sort((a, b) => {
			return a.createdAt < b.createdAt;
		});
		console.warn('messageList after: ', array[0]);
		setMessages(array);
	}, messageList);

	return (
        <View style={{
			width: Common.getLengthByIPhone7(0),
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<View style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				backgroundColor: 'white',
				alignItems: 'center',
				justifyContent: 'center',
			}}>
				<GiftedChat
					messages={messages}
					extraData={messages}
					bottomOffset={Platform.OS == 'ios' ? 70 : 0}
					keyboardShouldPersistTaps='handled'
					alwaysShowSend={true}
					showUserAvatar={false}
					renderAvatar={null}
					locale={ru}
					dateFormat='L'
					isAnimated={true}
					inverted={true}
					placeholder={'Отправить сообщение'}
					renderBubble={props => {
						return (
						<Bubble
							{...props}
							wrapperStyle={{
								right: {
									backgroundColor: 'rgba(50, 38, 97, 0.1)',
								},
								left: {
									backgroundColor: 'rgba(235, 94, 31, 0.1)',
								},
							}}
							textStyle={{
								right: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(18),
									lineHeight: Common.getLengthByIPhone7(21),
								},
								left: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(18),
									lineHeight: Common.getLengthByIPhone7(21),
								}
							}}
							linkStyle={{
								right: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(18),
									lineHeight: Common.getLengthByIPhone7(21),
								},
								left: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(18),
									lineHeight: Common.getLengthByIPhone7(21),
								}
							}}
							timeTextStyle={{
								left: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(10),
									lineHeight: Common.getLengthByIPhone7(12),
								},
								right: {
									color: colors.TEXT_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									fontSize: Common.getLengthByIPhone7(10),
									lineHeight: Common.getLengthByIPhone7(12),
								}
							}}
						/>
						);
					}}
					renderSend={props => {
						const {text, messageIdGenerator, user, onSend} = props
						return (<TouchableOpacity style={{

						}}
						onPress={() => {
							console.warn(text);
							
							if (text !== null && text.length) {
								sendMessage(text)
								.then(() => {
									// this.refreshChat();
									getMessages();
									Keyboard.dismiss();
									props.onSend({text: props.text.trim()}, true);
								})
								.catch(err => {

								});
							}
						}}>
							<Image source={require('./../../assets/ic-chat-send.png')}
								style={{
									width: Common.getLengthByIPhone7(24),
									height: Common.getLengthByIPhone7(24),
									marginBottom: Common.getLengthByIPhone7(10),
								}}
							/>
						</TouchableOpacity>);
						// return (<Send 
						// {...props}
						// label={'Отпр.'}
						// textStyle={{
						// 	color: colors.MAIN_COLOR,
						// }}
						// >

						// </Send>);
					}}
					textInputProps={{
						// editable: false,
						autoComplete: 'off',
						autoCorrect: false,
					}}
					renderComposer={props => {
						return <Composer {...props} textInputStyle={{
							width: Common.getLengthByIPhone7(240),
							minHeight: Common.getLengthByIPhone7(34),
							borderRadius: Common.getLengthByIPhone7(14),
							paddingLeft: Common.getLengthByIPhone7(10),
							// paddingRight: Common.getLengthByIPhone7(110),
							paddingTop: Common.getLengthByIPhone7(5),
							paddingBottom: 0,//Common.getLengthByIPhone7(15),
							marginRight: Common.getLengthByIPhone7(30),
							// marginLeft: Common.getLengthByIPhone7(50),
							// backgroundColor: 'transparent',
							backgroundColor: 'white',
							borderWidth: 0,
							// zIndex: 1,
							borderColor: '#C6C6C9',
							fontFamily: 'SFProDisplay-Regular',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(14),
							lineHeight: Common.getLengthByIPhone7(14)*1.4,
							color: 'black',
						}}/>;
					}}
					renderInputToolbar={props => {
						return <InputToolbar {...props} containerStyle={{
							marginBottom: Platform.OS === 'ios' ? -10 : 0,//Common.getLengthByIPhone7(20),
							marginLeft: Common.getLengthByIPhone7(20),
							width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
							borderWidth: 1,
							borderColor: '#D0D0D0',
							borderRadius: Common.getLengthByIPhone7(100),
							alignItems: 'center',
							justifyContent: 'center',
							flexDirection: 'row',
							minHeight: Common.getLengthByIPhone7(44),
							paddingLeft: 0,//Common.getLengthByIPhone7(15),
							paddingRight: Common.getLengthByIPhone7(15),
							backgroundColor: 'white',
							// backgroundColor: 'red',
						}}/>
					}}
					// onSend={messages => {
					// 	console.warn(messages);
					// 	if (messages !== null && messages.length) {
					// 		sendMessage(messages[0].text)
					// 		.then(() => {
					// 			// this.refreshChat();
					// 			getMessages();
					// 			Keyboard.dismiss();
					// 		})
					// 		.catch(err => {

					// 		});
					// 	}
					// }}
					user={{
						_id: userProfile ? userProfile.id : 0,
					}}
				/>
				<KeyboardAvoidingView keyboardVerticalOffset={-120} behavior={'padding'}/>
			</View>
		</View>
	);
};

const mstp = (state: RootState) => ({
	userProfile: state.user.userProfile,
	messageList: state.all.messageList,
});

const mdtp = (dispatch: Dispatch) => ({
    getMessages: () => dispatch.all.getMessages(),
	sendMessage: payload => dispatch.all.sendMessage(payload),
	setRequestGoingStatus: payload => dispatch.user.setRequestGoingStatus(payload),
});

export default connect(mstp, mdtp)(ChatScreen);
