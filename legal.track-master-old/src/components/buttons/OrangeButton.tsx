import React, { useEffect } from 'react';
import {TouchableOpacity, Text} from 'react-native';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const OrangeButton = ({style, title, onPress}) => {

	return (
		<TouchableOpacity style={[{
			width: Common.getLengthByIPhone7(350),
			height: Common.getLengthByIPhone7(42),
			borderRadius: Common.getLengthByIPhone7(10),
			alignItems: 'center',
			justifyContent: 'center',
			backgroundColor: colors.ORANGE_COLOR,
		}, style]}
		onPress={() => {
			if (onPress) {
				onPress();
			}
		}}>
			<Text style={{
				color: 'white',
				fontFamily: 'SFProText-Regular',
				fontWeight: 'bold',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(14),
				letterSpacing: -0.408,
			}}
			allowFontScaling={false}>
				{title}
			</Text>
		</TouchableOpacity>
	);
};

export default OrangeButton;