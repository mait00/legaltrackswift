import React, { useEffect, useLayoutEffect } from 'react';
import {View, Text, TouchableOpacity, Image, Platform, Keyboard} from 'react-native';
import { colors } from '../styles';
import Common from './../utilities/Common';
import { RootState, Dispatch } from './../store';
import { connect, useDispatch, useSelector } from 'react-redux';

const MainHeader = ({letter, title, type, menuMode, setMenuMode, showMenu, setShowMenu}) => {
	
	const [titleView, setTitleView] = React.useState(null);
	const [buttonView, setButtonView] = React.useState(null);
	const [refresh, setRefresh] = React.useState(false);

	useLayoutEffect(() => {
		// renderViews();
		setRefresh(!refresh);
	}, [menuMode]);

	useEffect(() => {
		// setTimeout(() => {
			renderViews();
		// }, 100);
		setTimeout(() => {
			setRefresh(!refresh);
		}, 500);
		
		return () => {
		// 	renderViews();
		setRefresh(!refresh);
		}
		Keyboard.dismiss();
	}, [menuMode]);

	useEffect(() => {
		renderViews();
	}, [refresh]);

	const renderViews = () => {
		if (menuMode) {
			setTitleView(<View style={{
				width: Common.getLengthByIPhone7(10),
				height: Common.getLengthByIPhone7(10),
			}} />);
			setButtonView(<TouchableOpacity style={{
				width: Common.getLengthByIPhone7(46),
				height: Common.getLengthByIPhone7(46),
				borderRadius: Common.getLengthByIPhone7(23),
				backgroundColor: 'white',
				alignItems: 'center',
				justifyContent: 'center',
				shadowColor: 'black',
				shadowOffset: { width: 0, height: 2 },
				shadowOpacity: 0.15,
				shadowRadius: 7,
				elevation: 4,
			}}
			onPress={() => {
				setMenuMode(false);
			}}>
				<Image source={require('./../assets/ic-menu-cancel.png')}
					style={{
						width: Common.getLengthByIPhone7(17),
						height: Common.getLengthByIPhone7(17),
						resizeMode: 'contain',
					}}
				/>
			</TouchableOpacity>);
		} else {
			setTitleView(<Text style={{
				color: colors.ORANGE_COLOR,
				fontFamily: 'Montserrat-Regular',
				fontWeight: 'bold',
				textAlign: 'left',
				fontSize: type === 'small' ? Common.getLengthByIPhone7(22) : Common.getLengthByIPhone7(25),
			}}
			allowFontScaling={false}>
				{letter}<Text style={{
					color: colors.MAIN_COLOR,
					fontFamily: 'Montserrat-Regular',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: type === 'small' ? Common.getLengthByIPhone7(22) : Common.getLengthByIPhone7(25),
				}}
				allowFontScaling={false}>
					{title}
				</Text>
			</Text>);
			setButtonView(<TouchableOpacity style={{
				width: Common.getLengthByIPhone7(46),
				height: Common.getLengthByIPhone7(46),
				borderRadius: Common.getLengthByIPhone7(23),
				backgroundColor: 'white',
				alignItems: 'center',
				justifyContent: 'center',
				shadowColor: 'black',
				shadowOffset: { width: 0, height: 2 },
				shadowOpacity: 0.15,
				shadowRadius: 7,
				elevation: 4,
			}}
			onPress={() => {
				setShowMenu(true);
				setMenuMode(false);
			}}>
				<Image source={require('./../assets/ic-menu.png')}
					style={{
						width: Common.getLengthByIPhone7(22),
						height: Common.getLengthByIPhone7(16),
						resizeMode: 'contain',
					}}
				/>
			</TouchableOpacity>);
		}
	}

	return (
		<View style={{
			paddingTop: Platform.OS === 'ios' ? Common.getLengthByIPhone7(62) : Common.getLengthByIPhone7(32),
			width: Common.getLengthByIPhone7(0),
			// height: Common.getLengthByIPhone7(50),
			paddingLeft: Common.getLengthByIPhone7(20),
			paddingRight: Common.getLengthByIPhone7(20),
			paddingBottom: Common.getLengthByIPhone7(24),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'space-between',
			flexDirection: 'row',
			// zIndex: 10,
		}}>
			{titleView}
			{buttonView}
		</View>
	);
};

const mstp = (state: RootState) => ({
	showMenu: state.buttons.showMenu,
	menuMode: state.buttons.menuMode,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowMenu: payload => dispatch.buttons.setShowMenu(payload),
	setMenuMode: payload => dispatch.buttons.setMenuMode(payload),
});

export default connect(mstp, mdtp)(MainHeader);