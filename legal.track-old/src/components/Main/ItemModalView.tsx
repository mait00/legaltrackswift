import React, { useEffect } from 'react';
import {Image, Alert, View, Text, TouchableOpacity, Share} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../../utilities/Common';
import { colors } from './../../styles';
import Modal from "react-native-modal";
import { APP_NAME } from './../../constants';

const ItemModalView = ({showItemMenu, onRename, setShowItemMenu, buttonIndex, getSubscribtions, data, deleteSubscription}) => {

	const navigation = useNavigation();

	const renderRow = (title, icon, style, action) => {
		return (<TouchableOpacity style={[{
			width: Common.getLengthByIPhone7(270),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'space-between',
			paddingLeft: Common.getLengthByIPhone7(30),
			paddingRight: Common.getLengthByIPhone7(30),
			paddingTop: Common.getLengthByIPhone7(7),
			paddingBottom: Common.getLengthByIPhone7(7),
		}, style]}
		onPress={() => {
			action();
		}}>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(16),
				lineHeight: Common.getLengthByIPhone7(22),
				letterSpacing: -0.408,
			}}
			allowFontScaling={false}>
				{title}
			</Text>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(30),
					height: Common.getLengthByIPhone7(30),
					resizeMode: 'contain',
				}}
			/>
		</TouchableOpacity>);
	}

    return (
		<Modal
			isVisible={showItemMenu}
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
					setShowItemMenu(false);
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
						{data ? (data.name ? data.name : data.value) : ''}
					</Text>
				</View>
				{data && data.status !== 'loading' ? renderRow('Переименовать', require('./../../assets/ic-button-rename.png'), {
					borderBottomColor: '#C6C6C8',
					borderBottomWidth: 1,
				}, () => {
					setShowItemMenu(false);
					onRename();
				}) : null}
				{data && data.status !== 'loading' ? renderRow('Поделиться', require('./../../assets/ic-button-share.png'), {
					borderBottomColor: '#C6C6C8',
					borderBottomWidth: 1,
				}, () => {
					console.warn(data);
					if (buttonIndex === 2) {
						Share.share({
							message: data.name + '\rИНН: ' + data.inn,
						})
						.then(() => {
							setShowItemMenu(false);
						});
					} else {
						// console.warn(data);
						// return;
						if (data.link) {
							Share.share({
								message: data.link,
							})
							.then(() => {
								setShowItemMenu(false);
							});
						} else {
							Alert.alert(APP_NAME, 'Формат ссылки неверен!');
						}
					}
				}) : null}
				{renderRow('Удалить', require('./../../assets/ic-button-delete.png'), {
					
				}, () => {
					console.warn(data);
					Alert.alert(
						APP_NAME,
						"Вы хотите удалить?",
						[
						  {
							text: "Нет",
							onPress: () => console.log("Cancel Pressed"),
							style: "cancel"
						  },
						  { text: "Да", onPress: () => {
								setShowItemMenu(false);
								deleteSubscription({id: data.id, type: buttonIndex === 2 ? 'company' : 'case'})
								.then(() => {
									getSubscribtions();
								})
								.catch(err => {

								});
						  }}
						]
					);
				})}
			</View>
		</Modal>
	);
};

const mstp = (state: RootState) => ({
	showItemMenu: state.buttons.showItemMenu,
	buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowItemMenu: payload => dispatch.buttons.setShowItemMenu(payload),
	deleteSubscription: payload => dispatch.all.deleteSubscription(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
});

export default connect(mstp, mdtp)(ItemModalView);