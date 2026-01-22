import React from 'react';
import { Text } from 'react-native';
import Common from './../utilities/Common';
import { colors } from './../styles';

const HeaderView = ({letter, word}) => {

	return (
		<Text style={{
			color: colors.ORANGE_COLOR,
			fontFamily: 'SFProText-Regular',
			fontWeight: '600',
			textAlign: 'center',
			fontSize: Common.getLengthByIPhone7(24),
			lineHeight: Common.getLengthByIPhone7(29),
			marginBottom: Common.getLengthByIPhone7(34),
		}}
		allowFontScaling={false}>
			{letter}<Text style={{
				color: colors.MAIN_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(24),
				lineHeight: Common.getLengthByIPhone7(29),
			}}
			allowFontScaling={false}>
				{word}
			</Text>
		</Text>
	);
};

export default HeaderView;
