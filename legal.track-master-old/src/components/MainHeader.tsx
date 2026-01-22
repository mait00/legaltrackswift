import React, { useEffect } from 'react';
import {View, Text, TouchableOpacity, Image} from 'react-native';
import { colors } from '../styles';
import Common from './../utilities/Common';
import { RootState, Dispatch } from './../store';
import { connect, useDispatch, useSelector } from 'react-redux';

const MainHeader = ({letter, title, type, showMenu, setShowMenu}) => {
	
	return (
		<View style={{
			paddingTop: Common.getLengthByIPhone7(62),
			width: Common.getLengthByIPhone7(0),
			// height: Common.getLengthByIPhone7(50),
			paddingLeft: Common.getLengthByIPhone7(20),
			paddingRight: Common.getLengthByIPhone7(20),
			paddingBottom: Common.getLengthByIPhone7(24),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'space-between',
			flexDirection: 'row',
		}}>
			<Text style={{
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
			</Text>
			<TouchableOpacity style={{
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
			}}>
				<Image source={require('./../assets/ic-menu.png')}
					style={{
						width: Common.getLengthByIPhone7(22),
						height: Common.getLengthByIPhone7(16),
						resizeMode: 'contain',
					}}
				/>
			</TouchableOpacity>
		</View>
	);
};

const mstp = (state: RootState) => ({
	showMenu: state.buttons.showMenu,
});

const mdtp = (dispatch: Dispatch) => ({
	setShowMenu: payload => dispatch.buttons.setShowMenu(payload),
});

export default connect(mstp, mdtp)(MainHeader);