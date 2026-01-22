import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, Platform, View, TouchableOpacity, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import PlaceholderView from '../../components/PlaceholderView';
import { GiftedChat, Send, Bubble } from 'react-native-gifted-chat';
import ru from 'dayjs/locale/ru';

const ChatScreen = ({userProfile, getMessages, messageList}) => {

	const navigation = useNavigation();
	const [messages, setMessages] = React.useState([]);

	// <PlaceholderView
	// 			icon={require('./../../assets/ic-placeholder-chat.png')}
	// 			title={'Готовы помочь!'}
	// 			subtitle={'Опишите вашу проблему и мы обязательно поможем вам!'}
	// 		/>

	useEffect(() => {
		getMessages();
	}, []);

	useEffect(() => {
		console.warn('messageList: ', messageList);
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
		array.sort((a, b) => {
			return a.createdAt < b.createdAt;
		});
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
						return (<Send 
						{...props}
						label={'Отпр.'}
						textStyle={{
							color: colors.MAIN_COLOR,
						}}
						>

						</Send>);
					}}
					onSend={messages => {
						// console.warn(messages);
						// if (messages !== null && messages.length) {
						// 	sendMessage(messages[0].text)
						// 	.then(() => {
						// 		this.refreshChat();
						// 		Keyboard.dismiss();
						// 	})
						// 	.catch(err => {

						// 	});
						// }
					}}
					user={{
						_id: userProfile.id,
					}}
				/>
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
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(ChatScreen);
