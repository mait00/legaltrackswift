import React, { useEffect } from 'react';
import {View, Text, TouchableOpacity, Image} from 'react-native';
import { colors } from '../styles';
import Common from './../utilities/Common';
import { RootState, Dispatch } from './../store';
import { connect, useDispatch, useSelector } from 'react-redux';

const PlaceholderView = ({icon, title, subtitle}) => {
	
	return (
		<View style={{
			width: Common.getLengthByIPhone7(0),
			flex: 1,
			paddingLeft: Common.getLengthByIPhone7(60),
			paddingRight: Common.getLengthByIPhone7(60),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
		}}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(120),
					height: Common.getLengthByIPhone7(120),
					resizeMode: 'contain',
				}}
			/>
			<Text style={{
				marginTop: Common.getLengthByIPhone7(18),
				color: colors.ORANGE_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(24),
				lineHeight: Common.getLengthByIPhone7(29),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
			<Text style={{
				marginTop: Common.getLengthByIPhone7(12),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(20),
				lineHeight: Common.getLengthByIPhone7(24),
			}}
			allowFontScaling={false}>
				{subtitle}
			</Text>
		</View>
	);
};

export default PlaceholderView;