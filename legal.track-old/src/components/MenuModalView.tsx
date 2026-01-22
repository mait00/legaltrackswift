import React, { useEffect } from 'react';
import {Image, Alert, View, Text, TouchableOpacity} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { RootState, Dispatch } from './../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../utilities/Common';
import { colors } from './../styles';
import Modal from "react-native-modal";
import { APP_NAME } from './../constants';

const statuses = {
	'0': 'Не юрист',
	'1': 'Инхаус',
	'2': 'Консалтинг',
	'3': 'Арбитражный управляющий',
};

const MenuModalView = ({showMenu, tarifs, setShowMenu, userProfile, logout}) => {

	const navigation = useNavigation();

	const renderRow = (title, subtitle, icon, style, action) => {
		return (<TouchableOpacity style={[{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}, style]}
		onPress={() => {
			action();
		}}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(36),
					height: Common.getLengthByIPhone7(36),
					resizeMode: 'contain',
				}}
			/>
			<Text style={{
				marginLeft: Common.getLengthByIPhone7(5),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(20),
				lineHeight: Common.getLengthByIPhone7(24),
				letterSpacing: -0.022,
			}}
			allowFontScaling={false}>
				{title}
			</Text>
			<Text style={{
				marginLeft: Common.getLengthByIPhone7(3),
				color: colors.ORANGE_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(20),
				lineHeight: Common.getLengthByIPhone7(24),
				letterSpacing: -0.022,
			}}
			allowFontScaling={false}>
				{subtitle}
			</Text>
		</TouchableOpacity>);
	}

    return (
		<Modal
			isVisible={showMenu}
			backdropColor={colors.MAIN_COLOR}
			backdropOpacity={0.54}
			style={{
				flex: 1,
				alignItems: 'center',
				justifyContent: 'flex-end',
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
					setShowMenu(false);
				}}>
					<Image source={require('./../assets/ic-menu-cancel.png')}
						style={{
							width: Common.getLengthByIPhone7(17),
							height: Common.getLengthByIPhone7(17),
							resizeMode: 'contain',
						}}
					/>
				</TouchableOpacity>
			</View>
			<View style={{
				width: Common.getLengthByIPhone7(0),
				marginBottom: -Common.getLengthByIPhone7(20),
				borderRadius: Common.getLengthByIPhone7(16),
				alignItems: 'center',
				justifyContent: 'flex-end',
				backgroundColor: 'white',
				paddingLeft: Common.getLengthByIPhone7(20),
				paddingRight: Common.getLengthByIPhone7(20),
			}}>
				{renderRow('Практика', '', require('./../assets/ic-menu-practice.png'), {
					marginBottom: Common.getLengthByIPhone7(16),
					marginTop: Common.getLengthByIPhone7(48),
				}, () => {
					setShowMenu(false);
					navigation.navigate('Practice');
				})}
				{renderRow('Тарифы', '', require('./../assets/ic-menu-tarifs.png'), {
					marginBottom: Common.getLengthByIPhone7(16),
				}, () => {
					setShowMenu(false);
					navigation.navigate('Tarifs');
				})}
				{renderRow('F.A.Q', '', require('./../assets/ic-menu-faq.png'), {
					marginBottom: Common.getLengthByIPhone7(16),
				}, () => {
					setShowMenu(false);
					navigation.navigate('Faq');
				})}
				{renderRow('Инструкция', '', require('./../assets/ic-menu-faq.png'), {
					marginBottom: Common.getLengthByIPhone7(16),
				}, () => {
					setShowMenu(false);
					navigation.navigate('Instruction');
				})}
				{renderRow('Техническая поддержка', '', require('./../assets/ic-menu-support.png'), {
					marginBottom: Common.getLengthByIPhone7(31),
				}, () => {
					setShowMenu(false);
					navigation.navigate('Chat');
				})}
				<View style={{
					marginBottom: Common.getLengthByIPhone7(49),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					padding: Common.getLengthByIPhone7(16),
					borderRadius: Common.getLengthByIPhone7(12),
					backgroundColor: colors.BG_VIEW,
					flexDirection: 'row',
					alignItems: 'flex-start',
					justifyContent: 'space-between',
				}}>
						<View style={{
							flexDirection: 'row',
							alignItems: 'center',
							justifyContent: 'flex-start',
						}}>
							<Image source={require('./../assets/ic-avatar.png')}
								style={{
									width: Common.getLengthByIPhone7(88),
									height: Common.getLengthByIPhone7(88),
									resizeMode: 'contain',
								}}
							/>
							<View style={{
								marginLeft: Common.getLengthByIPhone7(15),
								width: Common.getLengthByIPhone7(165),
							}}>
								<Text style={{
									width: Common.getLengthByIPhone7(165),
									color: colors.MAIN_COLOR,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: '600',
									textAlign: 'left',
									fontSize: Common.getLengthByIPhone7(16),
									lineHeight: Common.getLengthByIPhone7(19),
									letterSpacing: -0.022,
								}}
								allowFontScaling={false}>
									{userProfile ? userProfile.first_name + ' ' + userProfile.last_name : ''}
								</Text>
								<Text style={{
									marginTop: Common.getLengthByIPhone7(5),
									width: Common.getLengthByIPhone7(165),
									color: colors.TEXT_COLOR,
									opacity: 0.5,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									textAlign: 'left',
									fontSize: Common.getLengthByIPhone7(12),
									lineHeight: Common.getLengthByIPhone7(14),
									letterSpacing: -0.022,
								}}
								allowFontScaling={false}>
									{userProfile ? userProfile.email : ''}
								</Text>
								<Text style={{
									marginTop: Common.getLengthByIPhone7(3),
									width: Common.getLengthByIPhone7(165),
									color: colors.TEXT_COLOR,
									opacity: 0.5,
									fontFamily: 'SFProDisplay-Regular',
									fontWeight: 'normal',
									textAlign: 'left',
									fontSize: Common.getLengthByIPhone7(12),
									lineHeight: Common.getLengthByIPhone7(14),
									letterSpacing: -0.022,
								}}
								allowFontScaling={false}>
									{userProfile ? statuses[userProfile.type] : ''}
								</Text>
								<TouchableOpacity style={{
									marginTop: Common.getLengthByIPhone7(9),
								}}
								onPress={() => {
									setShowMenu(false);
									navigation.navigate('Profile');
								}}>
									<Text style={{
										color: colors.ORANGE_COLOR,
										fontFamily: 'SFProDisplay-Regular',
										fontWeight: 'normal',
										textAlign: 'left',
										fontSize: Common.getLengthByIPhone7(10),
										lineHeight: Common.getLengthByIPhone7(12),
										letterSpacing: -0.022,
										textDecorationLine: 'underline',
									}}
									allowFontScaling={false}>
										Изменить
									</Text>
								</TouchableOpacity>
							</View>
						</View>
						<TouchableOpacity style={{

						}}
						onPress={() => {
							Alert.alert(
								APP_NAME,
								"Вы хотите выйти?",
								[
								  {
									text: "Нет",
									onPress: () => console.log("Cancel Pressed"),
									style: "cancel"
								  },
								  { text: "Да", onPress: () => {
									  logout();
									  setShowMenu(false);
									  navigation.navigate('Phone');
								  }}
								]
							);
						}}>
							<Image source={require('./../assets/ic-logout.png')}
								style={{
									width: Common.getLengthByIPhone7(24),
									height: Common.getLengthByIPhone7(24),
									resizeMode: 'contain',
								}}
							/>
						</TouchableOpacity>
				</View>
			</View>
		</Modal>
	);
};

const mstp = (state: RootState) => ({
	showMenu: state.buttons.showMenu,
	userProfile: state.user.userProfile,
	tarifs: state.user.tarifs,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowMenu: payload => dispatch.buttons.setShowMenu(payload),
	logout: () => dispatch.user.logout(),
});

export default connect(mstp, mdtp)(MenuModalView);