import React, { useEffect } from 'react';
import {TouchableOpacity, Image} from 'react-native';
import Common from '../../utilities/Common';
import { useNavigation } from '@react-navigation/native';

const Close = () => {
	const navigation = useNavigation();

	return (
		<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(32),
			height: Common.getLengthByIPhone7(32),
			alignItems: 'flex-end',
			justifyContent: 'center',
		}}
		onPress={() => {
			navigation.goBack(null);
		}}>
			<Image
				source={require('./../../assets/ic-close.png')}
				style={{
					resizeMode: 'contain',
					width: Common.getLengthByIPhone7(24),
					height: Common.getLengthByIPhone7(24),
					// tintColor: 'black',
				}}
			/>
		</TouchableOpacity>
	);
};

export default Close;